# Create an environment

To create an environment, pick a name that's unique in your repository. For this example let's call it `test`.
The environment represents a cluster of AWS instances running Kubernetes on CoreOS, which share keys, credentials, and a configuration.

`ansible-playbook -e env=test -i hosts make-environment.yaml` will create your environment for you, 
including a new SSH keypair `test-key` and `test-key.pub`. 
This keypair is saved in your `~/.ssh` directory, and also copied to your environment's `secret-files` and `public-files` directories.

Once your environment is set up, change to its directory, for example, `cd test`.

## Sharing an environment

If you wish to share your environment, configurations, and secrets with others, 
Do your setup, then encrypt your secrets and push the results to the shared git repo (e.g. on GitHub).
Another team member can clone your repo and add the environment's vault-password file, then decrypt the secrets.
See [Sharing Secrets](docs/sharing-secrets.markdown) for more information.