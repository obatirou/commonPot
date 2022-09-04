# EXPERIMENTAL

Be careful with it.
Tests are not extented, not peer reviewed and only a side project to code more.

## Common Pot

A kind of opinionated multi-assets lockable tokenized vault

### Why ?

For fun

The idea came awith ERC4626 and thought it would be nice to have a multi asset tokenized vault for someone to pass on to whom it wants. Added a lock for holders.  
We could add strategies and more.  
It is opinionated as the configuration is dependant of a owner and token owners and far from the ERC4626.  
Token owners can only withdraw when assets are not locked. In the actual version, shares are only given by the owner of the vault.

### For who ?

Might be used by a power user and create a vault for its children/friends. Or by an anon team with a multi sig as owner for deployment. Or maybe nobody. I only want to ship more on the open, if it can be useful it is better though.

## Contribution

### You found a bug or optimization ?

Great !  
Drop a comment / issue / PR or any thing you want to share this finding.

### You like or do not like the implementation ?

I would be more than happy to discuss it with you.  
I mainly use twitter or github but my mail is also open.

## Custom template

It is based on [this template](https://github.com/obatirou/forge-template)  
With a lot of inspiration from https://github.com/smartcontractkit/foundry-starter-kit

-   Yarn as package manager
-   Husky for git hooks
-   Prettier for formatting
-   Makefile
-   .env for secrets
-   custom .gitignore
