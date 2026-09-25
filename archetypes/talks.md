---
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
date: '{{ .Date }}'
draft: true
description: ''
event: ''
location: ''
role: 'speaker'   # speaker | trainer | host | guest | judge | instructor | press
with: []
lang: 'en'
video: ''
slides: ''
source: ''
confidence: 'high'
# Talks are usually links out. Keep these unless you write a local page:
external_url: ''
build:
  render: never
---
