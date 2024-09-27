# HACS200 Honeypot

## Index
- [Overview](#overview)
    - [Research Question](#research-question)
    - [Hypothesis](#hypothesis)
    - [Procedure/Method](#experiment-proceduremethod)
- [Configuring GitHub](#configuring-github)
    - [Using GitHub Desktop](#using-github-desktop)
    - [Using Terminal](#using-terminal)
- [Making Changes](#making-changes)

## Overview 
### Research Question
How will attackers behave depending on the type of encryption they are faced with?
### Hypothesis 
**Null Hypothesis:** The hashing algorithm will have no effect on the behavior of the attacker in the data source.

**Alternative Hypothesis:** 
- The stronger the hashing algorithm the more time they will spend in the folder that uses that hashing algorithm.
- The stronger the hashing algorithm the deeper the attacker will go within the folder system that uses the hashing algorithm.

### Experiment Procedure/Method
We will deploy 4 honeypots each of the same configuration. The honeypots will contain 5 folders where 4 folders will be assigned 4 different hashing algorithms and 1 folder will be in plain text (used as a control). There will be some files inside the folders that will hold passwords which will be hashed with the assigned algorithm. 

We will keep track of how long an attacker stays within a folder system and also how deep they go.

**Hashing algorithms used:** SHA1, MD5, SHA256, SHA3

## Configuring GitHub

You can either install [GitHub Desktop](https://desktop.github.com/download/) or directly clone
this repository through your terminal. 

### Using GitHub Desktop
If you are using GitHub Desktop it will ask you to sign in. Then it will ask you to select 
a repository. Select the one titled "Cyber-HACS-Honeypot-1h-" 

Alternatively, you can select the Code button at the top of the repository. Then click "Open with GitHub Desktop"

It will prompt you with where you want to clone the repo.

### Using Terminal

If you are using your terminal select the Code button and click on HTTPS. Copy the link given and open up your terminal. In the terminal write "git clone" followed by the link you copied. Ensure you are in the folder where you want the cloned repository to be. 

## Making Changes
**Before you make any changes make sure you have the most up-to-date repository. On GitHub Desktop select fetch origin and on the terminal type ```git fetch```** 

You can open the repository on any text editor. Here are some popular ones:

- [VS Code](https://code.visualstudio.com/download)
- [Sublime Text](https://www.sublimetext.com/download)
- Vim (terminal)
- Emacs (GUI on terminal)
- [Notepad++](https://notepad-plus-plus.org/downloads/)
- [Brackets](https://brackets.io/?lang=en)

Once you've made changes (added files/folders, changed contents of files, etc) you would do these commands to update the changes onto the repo.

1. ```git add .``` 
2. ```git commit -m "brief description of changes"```
3. ```git push ```