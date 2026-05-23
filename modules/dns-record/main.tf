# A Records (name → IP addresses)
resource "azurerm_dns_a_record" "this" {
  for_each            = { for r in var.a_records : r.name => r }
  name                = each.value.name
  zone_name           = var.zone_name
  resource_group_name = var.resource_group_name
  ttl                 = coalesce(each.value.ttl, var.default_ttl)
  records             = each.value.records
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# CNAME Records (name → domain name)
resource "azurerm_dns_cname_record" "this" {
  for_each            = { for r in var.cname_records : r.name => r }
  name                = each.value.name
  zone_name           = var.zone_name
  resource_group_name = var.resource_group_name
  ttl                 = coalesce(each.value.ttl, var.default_ttl)
  record              = each.value.record
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# TXT Records (verification, SPF, DMARC, etc.)
resource "azurerm_dns_txt_record" "this" {
  for_each            = { for r in var.txt_records : r.name => r }
  name                = each.value.name
  zone_name           = var.zone_name
  resource_group_name = var.resource_group_name
  ttl                 = coalesce(each.value.ttl, var.default_ttl)
  tags                = var.tags

  dynamic "record" {
    for_each = each.value.records
    content {
      value = record.value
    }
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}
