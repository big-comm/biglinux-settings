from base_page import BaseSettingsPage, _


class DockerPage(BaseSettingsPage):
    def __init__(self, main_window, **kwargs):
        super().__init__(main_window, **kwargs)

        local_ip = self.get_local_ip()

        # Create the container (base method)
        content = self.create_scrolled_content()

        # Create the group (base method)
        docker_group = self.create_group(
            _("Docker"),
            _("Container service — enable to use containers below."),
            "docker",
        )
        content.append(docker_group)

        # Create the group (base method)
        container_group = self.create_group(
            _("Containers"), _("Manage container technologies."), "docker"
        )
        content.append(container_group)

        # ExpanderRows for organized container categories
        media_expander = self.create_expander_row(
            container_group,
            _("Media &amp; Cloud"),
            _("Media servers and cloud storage containers."),
            "docker-nextcloud-plus-symbolic",
        )
        network_expander = self.create_expander_row(
            container_group,
            _("Network &amp; Security"),
            _("Network tools and security containers."),
            "docker-adguard-symbolic",
        )
        dev_expander = self.create_expander_row(
            container_group,
            _("Development &amp; Tools"),
            _("Development stacks and utility containers."),
            "docker-lamp-symbolic",
        )

        ## Docker
        # Docker
        self.create_row(
            docker_group,
            _("Docker"),
            _("Enable Docker container engine."),
            "dockerEnable",
            "docker-symbolic",
        )

        ## Container
        # BigLinux Docker Nextcloud Plus
        nextCloud = self.create_row(
            media_expander,
            _("Nextcloud Plus"),
            _("Install Nextcloud Plus cloud storage container."),
            "nextcloud-plusInstall",
            "docker-nextcloud-plus-symbolic",
        )
        self.create_sub_row(
            media_expander,
            _("Nextcloud Plus"),
            _("Run Nextcloud Plus."),
            "nextcloud-plusRun",
            "docker-nextcloud-plus-symbolic",
            nextCloud,
            info_text=_(
                "Nextcloud Plus is running.\nAddress: http://localhost:8286\nand\nAddress: http://{}:8286"
            ).format(local_ip),
        )
        # BigLinux Docker AdGuard
        adguard = self.create_row(
            network_expander,
            _("AdGuard"),
            _("Install AdGuard Home DNS ad-blocker container."),
            "adguardInstall",
            "docker-adguard-symbolic",
        )
        self.create_sub_row(
            network_expander,
            _("AdGuard"),
            _("Run AdGuard."),
            "adguardRun",
            "docker-adguard-symbolic",
            adguard,
            info_text=_(
                "AdGuard is running.\nAddress: http://localhost:3030\nand\nAddress: http://{}:3030"
            ).format(local_ip),
        )
        # BigLinux Docker Jellyfin
        jellyfin = self.create_row(
            media_expander,
            _("Jellyfin"),
            _("Install Jellyfin media server container."),
            "jellyfinInstall",
            "docker-jellyfin-symbolic",
        )
        self.create_sub_row(
            media_expander,
            _("Jellyfin"),
            _("Run Jellyfin."),
            "jellyfinRun",
            "docker-jellyfin-symbolic",
            jellyfin,
            info_text=_(
                "Jellyfin is running.\nAddress: http://localhost:8096\nand\nAddress: http://{}:8096"
            ).format(local_ip),
        )
        # BigLinux Docker LAMP
        lamp = self.create_row(
            dev_expander,
            _("LAMP"),
            _("Install LAMP stack container (Linux, Apache, MySQL, PHP)."),
            "lampInstall",
            "docker-lamp-symbolic",
        )
        self.create_sub_row(
            dev_expander,
            _("LAMP"),
            _("Run LAMP."),
            "lampRun",
            "docker-lamp-symbolic",
            lamp,
            info_text=_(
                "LAMP is running.\nAddress: http://localhost:8080\nand\nAddress: http://{}:8080"
            ).format(local_ip),
        )
        # BigLinux Docker Portainer Client
        portainer = self.create_row(
            dev_expander,
            _("Portainer Client"),
            _("Install Portainer Agent container for cluster management."),
            "portainer-clientInstall",
            "docker-portainer-client-symbolic",
        )
        self.create_sub_row(
            dev_expander,
            _("Portainer Client"),
            _("Run Portainer Client."),
            "portainer-clientRun",
            "docker-portainer-client-symbolic",
            portainer,
            info_text=_(
                "Portainer Client is running.\nAddress: http://localhost:9000\nand\nAddress: http://{}:9000"
            ).format(local_ip),
        )
        # BigLinux Docker SWS
        sws = self.create_row(
            dev_expander,
            _("SWS"),
            _("Install SWS static web server container."),
            "swsInstall",
            "docker-sws-symbolic",
        )
        self.create_sub_row(
            dev_expander,
            _("SWS"),
            _("Run SWS."),
            "swsRun",
            "docker-sws-symbolic",
            sws,
            info_text=_(
                "SWS is running.\nAddress: http://localhost:8182\nand\nAddress: http://{}:8182"
            ).format(local_ip),
        )
        # BigLinux Docker V2RayA
        v2raya = self.create_row(
            network_expander,
            _("V2RayA"),
            _("Install V2RayA network proxy container."),
            "v2rayaInstall",
            "docker-v2raya-symbolic",
        )
        self.create_sub_row(
            network_expander,
            _("V2RayA"),
            _("Run V2RayA."),
            "v2rayaRun",
            "docker-v2raya-symbolic",
            v2raya,
            info_text=_(
                "V2RayA is running.\nAddress: http://localhost:2017\nand\nAddress: http://{}:2017"
            ).format(local_ip),
        )
        # Open Notebook
        openNotebook = self.create_row(
            dev_expander,
            _("Open Notebook"),
            _(
                "Install An open source, privacy-focused alternative to Google's Notebook LM!"
            ),
            "openNotebookInstall",
            "openNotebook-symbolic",
        )
        self.create_sub_row(
            dev_expander,
            _("Open Notebook"),
            _("Run Open Notebook."),
            "openNotebookRun",
            "openNotebook-symbolic",
            openNotebook,
            info_text=_(
                "Open Notebook is running.\nAddress: http://localhost:8502\nand\nAddress: http://{}:8502"
            ).format(local_ip),
        )
