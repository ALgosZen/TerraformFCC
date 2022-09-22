variable "expiration_day" {
  type        = string
  description = "Custom lifecycle rule to choose Expiration."
  default     = "2555"
}

variable "custom_lc_rule" {
  type        = map(string)
  description = "Custom prod lifecycle rule to choose days until transition to Standard-IA, days until transition to Glacier, and days until objects expire."
  default = {
    "trans_standard_ia_day" = "30",
    "trans_glacier_day"     = "90",
    "expiration_day"        = "2555"
  }
}
