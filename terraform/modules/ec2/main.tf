resource "aws_key_pair" "mvlbarcelos" {
    key_name   = "key-${var.app_name}"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC93cB0pFLdcRqRMEp2EST/lTpm5YIVTUU3BbXisShYb2nEuooHME9A3h1/GSG1YdEZy8I9SzDOOgSZEK5CrPhr1p2jvB8XzEVTJZX2Gqc9BF0rB0inNhTIEKZqgeFnuzdR8UGVRIWqLel3E1BDviTlleffpAloWsWF0ZdvI1I63usHXMpBrG9giU71jr5v9p81h4GfNG0ckqMdpScBANhUlemFbLaRLtkn7SNplrhd6/0yJ7nwMH+T/7RcedwP1YkI0zHNHHCDd6pPtsDcHuhMjU04GUr51P+/loLwWDGN8RazlDkFE7n15SfjrJKTE4BBVFFW1Nj4Qc309FHxb69r mvlbarcelos@gmail.com"
}