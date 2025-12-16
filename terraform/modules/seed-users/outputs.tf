# terraform/modules/seed-users/outputs.tf

output "seed_users_status" {
  value       = "Test users seeded successfully"
  description = "Status of user seeding process"
}

output "test_users_credentials" {
  value = [
    for user in local.test_users : {
      email    = user.email
      password = user.password
      name     = user.name
    }
  ]
  sensitive   = true
  description = "Test user credentials (email, password, name)"
}

output "test_user_noyblum_password" {
  value       = random_password.test_user_noyblum.result
  sensitive   = true
  description = "Password for noyblum@blumenfeld.com"
}

output "test_user_davidod_password" {
  value       = random_password.test_user_davidod.result
  sensitive   = true
  description = "Password for davidod@blumenfeld.com"
}

output "test_user_hanochblum_password" {
  value       = random_password.test_user_hanochblum.result
  sensitive   = true
  description = "Password for hanochblum@blumenfeld.com"
}
