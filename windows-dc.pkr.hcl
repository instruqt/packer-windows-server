source "googlecompute" "windows-dc" {
  communicator      = "winrm"
  disk_size         = 100
  disk_type         = "pd-ssd"
  image_description = "Windows Domain Controller instance for use within Instruqt platform"
  image_name        = "windows-dc-{{timestamp}}"
  image_family      = "windows-dc"
  machine_type      = "n1-standard-2"
  metadata = {
    windows-shutdown-script-ps1 = "C:/cleanup-packer.ps1"
    windows-startup-script-cmd  = "winrm quickconfig -quiet & net user /add packer_user & net localgroup administrators packer_user /add & winrm set winrm/config/service/auth @{Basic=\"true\"}"
  }
  network             = "default"
  on_host_maintenance = "TERMINATE"
  project_id          = "instruqt"
  region              = "europe-west1"
  zone                = "europe-west1-b"
  source_image_family = "windows-2022"
  tags                = ["allow-winrm-ingress-to-packer"]
  winrm_insecure      = true
  winrm_use_ssl       = true
  winrm_username      = "packer_user"
}

build {
  sources = ["source.googlecompute.windows-dc"]

  provisioner "file" {
    destination = "C:/cleanup-packer.ps1"
    source      = "./scripts/cleanup-packer.ps1"
  }
  provisioner "powershell" {
    elevated_user     = "SYSTEM"
    elevated_password = ""
    scripts = [
      "./scripts/disable-uac.ps1",
      "./scripts/miscellaneous.ps1",
      "./scripts/browser-settings.ps1",
      "./scripts/display-settings.ps1",
      "./scripts/install-openssh.ps1",
      "./scripts/install-ad-domain-services.ps1",
    ]
    valid_exit_codes = [0, 3010]
  }
  provisioner "windows-restart" {
    restart_timeout = "60m"
  }
  provisioner "powershell" {
    elevated_user     = "SYSTEM"
    elevated_password = ""
    scripts = [
      "./scripts/install-ad-domain-forest.ps1",
    ]
  }
  provisioner "windows-restart" {
    restart_timeout = "60m"
  }
  provisioner "powershell" {
    inline = [
      "Set-Service -Name sshd -StartupType 'Automatic'",
      "New-Item -Path \"C:/\" -Name \"packer.done\" -ItemType \"file\"",
      "GCESysprep -NoShutdown",
    ]
  }
}
