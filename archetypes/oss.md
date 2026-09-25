---
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
date: '{{ .Date }}'
draft: true
description: ''
repo: 'owner/name'
ref: ''            # e.g. 'PR #125'
status: 'merged'   # merged | open | closed
role: 'author'     # author | co-maintainer | contributor
source: ''
confidence: 'high'
external_url: ''
build:
  render: never
---
