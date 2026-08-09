output "controller" {
  description = "Ansible Automation Platform Controller"
  value = {
    public_ip  = aws_instance.controller.public_ip
    private_ip = aws_instance.controller.private_ip
    web_ui     = "https://${aws_instance.controller.public_ip}"
    ssh        = "ssh -i ${var.private_key_path} ec2-user@${aws_instance.controller.public_ip}"
  }
}

output "targets" {
  description = "Target servers by environment"
  value = {
    for key, instance in aws_instance.targets : key => {
      public_ip   = instance.public_ip
      private_ip  = instance.private_ip
      environment = instance.tags["Environment"]
      cis_level   = instance.tags["CISLevel"]
    }
  }
}

output "summary" {
  description = "Quick reference"
  value = <<-EOT

  ══════════════════════════════════════════════
   INFRASTRUCTURE DEPLOYED
  ══════════════════════════════════════════════

   Controller: ${aws_instance.controller.public_ip}
   Web UI:     https://${aws_instance.controller.public_ip}

   DEV:
   ${join("\n   ", [for k, v in aws_instance.targets : "  ${k}: ${v.private_ip}" if v.tags["Environment"] == "dev"])}

   STAGING:
   ${join("\n   ", [for k, v in aws_instance.targets : "  ${k}: ${v.private_ip}" if v.tags["Environment"] == "staging"])}

   PROD:
   ${join("\n   ", [for k, v in aws_instance.targets : "  ${k}: ${v.private_ip}" if v.tags["Environment"] == "prod"])}

  ══════════════════════════════════════════════
  EOT
}
