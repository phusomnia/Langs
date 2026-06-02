# 1. Introduction

## 1.1 What is Bash?

Bash (Bourne Again SHell) is a command-line interpreter and scripting language commonly used on Linux, macOS, and Unix-like operating systems.

A shell acts as a bridge between the user and the operating system. It reads commands, interprets them, and executes programs.

Example:

```bash
echo "Hello World"
```

Output:

```text
Hello World
```

Bash is the default shell on many Linux distributions and remains one of the most important tools for system administration, automation, DevOps, and software development.

---

## 1.2 Why Learn Bash?

Bash is one of the most valuable skills for anyone working with Linux-based systems.

Learning Bash enables you to:

* Automate repetitive tasks
* Manage servers
* Process files and logs
* Build deployment pipelines
* Create backup systems
* Integrate APIs
* Perform system administration

Without Bash:

```text
Task
 ├─ Open terminal
 ├─ Run command
 ├─ Repeat command
 ├─ Repeat again
 └─ Repeat again
```

With Bash:

```text
Task
 └─ Run one script
```

Automation saves time, reduces human error, and improves productivity.

---

## 1.3 Common Use Cases

### System Administration

Managing users:

```bash
useradd john
```

Managing services:

```bash
systemctl restart nginx
```

### File Management

Rename multiple files:

```bash
for file in *.txt
do
    mv "$file" "${file%.txt}.bak"
done
```

### Backup Automation

Create archives:

```bash
tar -czf backup.tar.gz data/
```

### Log Analysis

Search application errors:

```bash
grep ERROR app.log
```

### API Automation

Call external services:

```bash
curl https://api.example.com/users
```

### DevOps

Common automation tasks:

* Docker deployment
* Kubernetes management
* CI/CD pipelines
* Infrastructure provisioning

---

## 1.4 Bash vs Other Shells

Several shell implementations exist.

| Shell | Description                         |
| ----- | ----------------------------------- |
| sh    | Original Bourne Shell               |
| bash  | Bourne Again Shell                  |
| zsh   | Extended shell with modern features |
| ksh   | Korn Shell                          |
| fish  | User-friendly interactive shell     |

Example:

```bash
echo $SHELL
```

Possible output:

```text
/bin/bash
```

Bash remains the most widely supported shell for scripting and automation.

---

## 1.5 Requirements

Before learning Bash scripting, you should have:

* Basic Linux knowledge
* Familiarity with terminal commands
* A Linux, macOS, or WSL environment
* A text editor

Recommended editors:

* VS Code
* Vim
* Nano
* Neovim

Verify Bash installation:

```bash
bash --version
```

Example output:

```text
GNU bash, version 5.x
```

Create your first script:

```bash
touch hello.sh
```

Add execute permissions:

```bash
chmod +x hello.sh
```

Run the script:

```bash
./hello.sh
```

You are now ready to begin learning Bash scripting.
