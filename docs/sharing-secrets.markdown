# Secure sharing of secrets

## Where to place files containing secrets

Each environment directory has a subdirectory `secret-files`, to hold files that have secret information.
For example, you can place SSH private keys, SSL private keys, and Docker credential files  in the `secret-files` directory.

Secrets that are YAML files, and used as "vars files" with Ansible, may be placed in the `secret-files/vars` directory.

Note that when you create a new environment using the `make-environment.yaml` playbook, an SSH keypair is created for you. 
The private key is put in the `secret-files` directory, and the public key in the `public-files` directory.

The `secret-files` directory is mentioned in the `.gitignore` file, so your secret files will never be included in a git commit or pushed to a remote git repository such as GitHub.

## Encrypting your secrets

When you create an environment using the `make-environment.yaml` playbook, a random Ansible vault password is created and saved in the `vault-password` file. 
Of course, this file is mentioned in `.gitignore`, so it's never pushed to a remote repository. It stays on your local machine.
 
To encrypt your secrets, run the `encrypt-secret-files.yaml` playbook. Rerun this playbook whenever you add, change, or delete any secrets.

## Sharing your secrets

You can safely push your repository to a remote Git sever such as GitHub, even if it's public.
All secrets are encrypted using the vault password for that environment.
Anyone can clone the repository, but cannot decrypt the secrets.

To give a team member access to the secrets for an environment, provide them the password from your `vault-password` file for that environment.
The team member creates a `vault-password` file containing the password, then runs `decrypt-secrets.yaml`. 
All the secrets are decrypted into the `secret-files` directory.

## Step by step

The original creator of the environment follows these steps:

1. Create an environment as described in the README. This will automatically add a new SSH keypair to the environment, and create a random password saved in `vault-password`.
2. Add additional secret files to the `secret-files` directory, as appropriate. These can be binary or text, but should be relatively small files.
2. Add secret Ansible vars files to the `secret-files/vars' directory, as needed.
3. `cd <env>` where `<env>` is the name of your environment.
3. `ansible-playbook ../encrypt-secret-files.yaml`.
4. Commit the changes using Git, and push the changes to a shared repository such as GitHub. 

The team member who wishes to use the environment follows these steps:

2. Clone the shared repository locally.
1. Ask the creator for the environment's `vault-password` file contents. It will be a random string of 20 or so letters. Create your own `vault-password` file in the environment directory, with the password as its contents. 
3. `cd <env>` where `<env>` is the name of the environment.
4. `ansible-playbook ../decrypt-secret-files.yaml`.
5. Copy the SSH keys for the environment to your `~/.ssh` directory.

If you need to add or change secret files, make your changes in your `secret-files` directory, then run the `encrypt-secret-files.yaml` playbook and commit/push.
 
Then, other team members can pull your changes and run the `decrypt-secret-files` playbook to update their local secret files.