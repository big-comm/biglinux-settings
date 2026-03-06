from base_page import BaseSettingsPage, _


class AIPage(BaseSettingsPage):
    def __init__(self, main_window, **kwargs):
        super().__init__(main_window, **kwargs)

        local_ip = self.get_local_ip()

        # Create the container (base method)
        content = self.create_scrolled_content()

        # Create the AI Interfaces group
        aiGui = self.create_group(
            _("AI Interfaces"),
            _("Graphical interface for artificial intelligence."),
            "ai",
        )
        content.append(aiGui)

        # Create the group Ollama (base method)
        ollamaServer = self.create_group(
            _("Ollama Server"),
            _("Choose which Ollama server is best for your hardware."),
            "ai",
        )
        content.append(ollamaServer)

        # ExpanderRow to collapse the 4 Ollama variants
        ollama_expander = self.create_expander_row(
            ollamaServer,
            _("Ollama Variants"),
            _("Select the variant that matches your GPU hardware."),
            "ollama-symbolic",
        )

        # ChatAI
        self.create_row(
            aiGui,
            _("ChatAI"),
            _("A variety of chats like Plasmoid for your KDE Plasma desktop."),
            "chatai",
            "chatai-symbolic",
        )
        # Ollama LAB
        self.create_row(
            aiGui,
            _("Ollama LAB"),
            _("Graphical interface for managing Ollama models and chat."),
            "ollamaLab",
            "ollama-symbolic",
        )
        # ChatBox
        self.create_row(
            aiGui,
            _("ChatBox"),
            _("User-friendly Desktop Client App for AI Models/LLMs."),
            "chatbox",
            "chatbox-symbolic",
        )
        # LM Studio
        self.create_row(
            aiGui,
            _("LM Studio"),
            _(
                "LM Studio - A desktop app for exploring and running large language models locally."
            ),
            "lmStudio",
            "lmstudio-symbolic",
        )
        # Open Notebook
        self.create_row(
            aiGui,
            _("Open Notebook"),
            _("An open source, privacy-focused alternative to Google's Notebook LM!"),
            "openNotebookInstall",
            "openNotebook-symbolic",
        )
        # ComfyUI
        link_comfyui = "https://github.com/Comfy-Org/ComfyUI"
        comfyUI = self.create_row(
            aiGui,
            _("ComfyUI (GPU ONLY)"),
            _("The most powerful and modular visual AI engine and application."),
            "comfyUI",
            "comfyUI-symbolic",
            timeout=1200,
            link_url=link_comfyui,
        )
        self.create_sub_row(
            aiGui,
            _("ComfyUI Server"),
            _(
                "Start the ComfyUI server."
            ),
            "comfyUIRun",
            "comfyUI-symbolic",
            comfyUI,
            info_text=_(
                "ComfyUI server is running.\nAddress: http://localhost:8188\nand\nAddress: http://{}:8188"
            ).format(local_ip),
        )
        # Ollama CPU
        ollama = self.create_row(
            ollama_expander,
            _("OllamaCPU"),
            _("Local AI server. For CPUs only."),
            "ollamaCpu",
            "ollama-symbolic",
            info_text=_("Ollama server is running.\nAddress: http://localhost:11434"),
        )
        self.create_sub_row(
            ollama_expander,
            _("Share Ollama"),
            _("Share ollama on the local network."),
            "ollamaShare",
            "ollama-symbolic",
            ollama,
            info_text=_("Ollama server is running.\nAddress: http://{}:11434").format(
                local_ip
            ),
        )
        # Ollama Vulkan
        ollama = self.create_row(
            ollama_expander,
            _("Ollama Vulkan"),
            _("Local AI server. For CPUs, AMD/Nvidia and integrated GPUs."),
            "ollamaVulkan",
            "ollama-symbolic",
            info_text=_("Ollama server is running.\nAddress: http://localhost:11434"),
        )
        self.create_sub_row(
            ollama_expander,
            _("Share Ollama"),
            _("Share ollama on the local network."),
            "ollamaShare",
            "ollama-symbolic",
            ollama,
            info_text=_("Ollama server is running.\nAddress: http://{}:11434").format(
                local_ip
            ),
        )
        # Ollama Nvidia CUDA
        ollama = self.create_row(
            ollama_expander,
            _("Ollama Nvidia CUDA"),
            _("Local AI server. For newer Nvidia GPUs, starting from the 2000 series."),
            "ollamaNvidia",
            "ollama-symbolic",
            info_text=_("Ollama server is running.\nAddress: http://localhost:11434"),
        )
        self.create_sub_row(
            ollama_expander,
            _("Share Ollama"),
            _("Share ollama on the local network."),
            "ollamaShare",
            "ollama-symbolic",
            ollama,
            info_text=_("Ollama server is running.\nAddress: http://{}:11434").format(
                local_ip
            ),
        )
        # Ollama AMD ROCm
        ollama = self.create_row(
            ollama_expander,
            _("Ollama AMD ROCm"),
            _(
                "Local AI server. For newer AMD GPUs, starting from the 6000 series.\nConsider using Vulkan, in many tests, Vulkan performed better than ROCm."
            ),
            "ollamaAmd",
            "ollama-symbolic",
            info_text=_("Ollama server is running.\nAddress: http://localhost:11434"),
        )
        self.create_sub_row(
            ollama_expander,
            _("Share Ollama"),
            _("Share ollama on the local network."),
            "ollamaShare",
            "ollama-symbolic",
            ollama,
            info_text=_("Ollama server is running.\nAddress: http://{}:11434").format(
                local_ip
            ),
        )
