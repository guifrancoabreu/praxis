package br.praxis.android.ui.feedback

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import br.praxis.android.R
import br.praxis.android.data.FeedbackSender
import br.praxis.android.design.Praxis
import br.praxis.android.design.Tokens
import br.praxis.android.design.components.PrimaryButton
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

@Composable
fun FeedbackScreen(onBack: () -> Unit, scope: CoroutineScope) {
    var type by rememberSaveable { mutableStateOf("bug") }
    var details by rememberSaveable { mutableStateOf("") }
    var email by rememberSaveable { mutableStateOf("") }
    var sending by remember { mutableStateOf(false) }
    var result by remember { mutableStateOf<FeedbackResult?>(null) }
    val emailInvalid = email.isNotBlank() && !android.util.Patterns.EMAIL_ADDRESS.matcher(email.trim()).matches()

    Column(Modifier.fillMaxSize().background(Praxis.colors.background)) {
        Row(
            modifier = Modifier.fillMaxWidth().statusBarsPadding().padding(horizontal = Tokens.Spacing.s1, vertical = Tokens.Spacing.s1),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = onBack) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.action_back), tint = Praxis.colors.textPrimary)
            }
            Text(stringResource(R.string.feedback_title), style = MaterialTheme.typography.titleSmall, color = Praxis.colors.textPrimary)
        }
        Column(
            modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).navigationBarsPadding().padding(Tokens.Spacing.s5),
            verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s4),
        ) {
            Text(stringResource(R.string.feedback_intro), style = MaterialTheme.typography.bodyLarge, color = Praxis.colors.textSecondary)
            Text(stringResource(R.string.feedback_type_label), style = MaterialTheme.typography.titleSmall, color = Praxis.colors.textPrimary)
            Row(horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s2)) {
                TypeChoice(stringResource(R.string.feedback_bug), selected = type == "bug", enabled = !sending) { type = "bug" }
                TypeChoice(stringResource(R.string.feedback_suggestion), selected = type == "suggestion", enabled = !sending) { type = "suggestion" }
            }
            OutlinedTextField(
                value = details,
                onValueChange = { details = it.take(MAX_DETAILS_LENGTH); result = null },
                modifier = Modifier.fillMaxWidth(),
                label = { Text(stringResource(R.string.feedback_details)) },
                supportingText = { Text("${details.length}/$MAX_DETAILS_LENGTH") },
                minLines = 5,
                maxLines = 8,
                enabled = !sending,
            )
            OutlinedTextField(
                value = email,
                onValueChange = { email = it; result = null },
                modifier = Modifier.fillMaxWidth(),
                label = { Text(stringResource(R.string.feedback_email)) },
                supportingText = { Text(stringResource(R.string.feedback_email_required)) },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                singleLine = true,
                enabled = !sending,
                isError = emailInvalid,
            )
            when (result) {
                FeedbackResult.Success -> Text(stringResource(R.string.feedback_success), color = Praxis.colors.accent, style = MaterialTheme.typography.bodyMedium)
                FeedbackResult.Failure -> Text(stringResource(R.string.feedback_error), color = Praxis.colors.accent, style = MaterialTheme.typography.bodyMedium)
                null -> Unit
            }
            PrimaryButton(
                text = if (sending) stringResource(R.string.feedback_sending) else stringResource(R.string.feedback_send),
                onClick = {
                    sending = true
                    result = null
                    scope.launch {
                        result = runCatching { FeedbackSender.send(type, details.trim(), email.trim()) }
                            .fold({ FeedbackResult.Success }, { FeedbackResult.Failure })
                        sending = false
                        if (result == FeedbackResult.Success) {
                            details = ""
                            email = ""
                        }
                    }
                },
                enabled = details.isNotBlank() && email.isNotBlank() && !emailInvalid && !sending,
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}

@Composable
private fun TypeChoice(label: String, selected: Boolean, enabled: Boolean, onClick: () -> Unit) {
    TextButton(
        onClick = onClick,
        enabled = enabled,
        modifier = Modifier.clip(RoundedCornerShape(Tokens.Radius.full)).background(
            if (selected) Praxis.colors.chipSelectedBackground else Praxis.colors.chipBackground,
        ),
    ) {
        Text(label, color = if (selected) Praxis.colors.chipSelectedContent else Praxis.colors.chipContent)
    }
}

private enum class FeedbackResult { Success, Failure }

private const val MAX_DETAILS_LENGTH = 5_000
