# How to use it?

````python
load('ext://git_resource', 'git_resource')

repo = git_resource("https://github.com/calebebrim/tiltit.git", ref="master")

load(repo.child("Tiltfile"), "my_helper_func")

````

# Helper functions

## Event Stream
- 