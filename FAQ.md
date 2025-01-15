# Questions to why some choices

1. Not saving SSH on a bind mount
   > ssh server doesn't like sharing with windows the ssk keys
2. Makefile contains all the quick command needed to deploy the stack
3. To recreate a runner just delete directory `./services/runner/data` and `make runner`
4. Registry-ui require using http://127.0.0.1:8080 localhost not working
