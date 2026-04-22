from base_page import BaseSettingsPage, _


class DeveloperPage(BaseSettingsPage):
    def __init__(self, main_window, **kwargs):
        super().__init__(main_window, **kwargs)

        content = self.create_scrolled_content()

        ai_coding_group = self.create_group(
            _("AI Coding Assistants"),
            _("Open-source coding agents powered by language models."),
            "developer",
        )
        content.append(ai_coding_group)

        # OpenClaude — open-source coding agent CLI (200+ models via OpenAI-compat)
        link_openclaude = "https://github.com/Gitlawb/openclaude"
        self.create_row(
            ai_coding_group,
            _("OpenClaude"),
            _(
                "Open-source coding-agent CLI for OpenAI, Gemini, DeepSeek, Ollama and 200+ models. Installs nodejs, npm and ripgrep as dependencies."
            ),
            "openclaude",
            "openclaude-symbolic",
            timeout=600,
            link_url=link_openclaude,
        )
