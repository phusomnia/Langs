# 2. Shell Fundamentals

Shell Fundamentals form the foundation of Bash scripting. Before learning loops, functions, or automation, it is important to understand how Bash interprets commands, expands variables, and executes programs.

Many Bash bugs are caused by misunderstandings of shell parsing, quoting, and expansion rather than incorrect programming logic.

---

# 2.1 Shell Execution Model

## How Bash Executes Commands

When you type a command:

```bash
echo "Hello World"
```

Bash performs several steps:

1. Read input
2. Tokenize the command
3. Perform shell expansions
4. Resolve command location
5. Execute the command
6. Return an exit status

Example:

```bash
name="John"

echo "Hello $name"
```

Before execution, Bash expands `$name` into `John`.

The command becomes:

```bash
echo "Hello John"
```

Bash then executes `echo`.

---

## Tokens and Parsing

Bash first breaks input into tokens.

Example:

```bash
cp file.txt backup.txt
```

Tokens:

```text
cp
file.txt
backup.txt
```

The first token is usually the command.

Remaining tokens become arguments.

---

## Commands and Arguments

General format:

```bash
command argument1 argument2 ...
```

Example:

```bash
ls -l /home
```

Command:

```text
ls
```

Arguments:

```text
-l
/home
```

---

## Exit Status

Every command returns an exit status.

Success:

```text
0
```

Failure:

```text
non-zero
```

Example:

```bash
mkdir project

echo $?
```

Output:

```text
0
```

Check command success:

```bash
if mkdir project; then
    echo "Created"
fi
```

---

# 2.2 Script Structure

## Shebang

Every script should begin with a shebang.

Recommended:

```bash
#!/usr/bin/env bash
```

Alternative:

```bash
#!/bin/bash
```

The shebang tells the operating system which interpreter should run the script.

---

## Comments

Single-line comments:

```bash
# This is a comment
```

Example:

```bash
# Create backup archive
tar -czf backup.tar.gz data/
```

---

## Running Scripts

Create a script:

```bash
touch hello.sh
```

Add content:

```bash
#!/usr/bin/env bash

echo "Hello World"
```

Make executable:

```bash
chmod +x hello.sh
```

Execute:

```bash
./hello.sh
```

---

## File Permissions

View permissions:

```bash
ls -l script.sh
```

Example:

```text
-rwxr-xr-x
```

Permission types:

| Symbol | Meaning |
| ------ | ------- |
| r      | Read    |
| w      | Write   |
| x      | Execute |

---

# 2.3 Variables and Data Types

## Variable Declaration

Syntax:

```bash
name="John"
```

Access value:

```bash
echo "$name"
```

Output:

```text
John
```

No spaces around `=`:

```bash
name="John"
```

Incorrect:

```bash
name = "John"
```

---

## Environment Variables

Environment variables are inherited by child processes.

Example:

```bash
export APP_ENV=production
```

View:

```bash
echo "$APP_ENV"
```

Common environment variables:

| Variable | Description            |
| -------- | ---------------------- |
| HOME     | User home directory    |
| PATH     | Executable search path |
| USER     | Current user           |
| SHELL    | Current shell          |

---

## Readonly Variables

Prevent modification:

```bash
readonly VERSION="1.0"
```

Attempting to change it will fail.

---

## Local Variables

Inside functions:

```bash
greet() {
    local name="John"
    echo "$name"
}
```

Local variables reduce side effects.

---

## Special Variables

Current script:

```bash
echo "$0"
```

First argument:

```bash
echo "$1"
```

Argument count:

```bash
echo "$#"
```

Current process ID:

```bash
echo "$$"
```

Last exit status:

```bash
echo "$?"
```

Background process ID:

```bash
echo "$!"
```

These special parameters are built into Bash.

---

# 2.4 Quoting

Quoting controls how Bash interprets characters.

---

## Single Quotes

Everything is treated literally.

```bash
name="John"

echo '$name'
```

Output:

```text
$name
```

---

## Double Quotes

Allow variable expansion.

```bash
echo "$name"
```

Output:

```text
John
```

---

## Escape Characters

Escape special characters:

```bash
echo "He said \"Hello\""
```

Output:

```text
He said "Hello"
```

---

## ANSI-C Quoting

Supports escape sequences.

```bash
echo $'Line1\nLine2'
```

Output:

```text
Line1
Line2
```

---

## Common Quoting Mistakes

Bad:

```bash
file="my file.txt"

rm $file
```

Bash sees:

```bash
rm my file.txt
```

Good:

```bash
rm "$file"
```

Always quote variables unless there is a specific reason not to.

---

# 2.5 Shell Expansion

Shell expansion is one of the most important Bash concepts.

Bash performs expansions before executing commands. The official order includes brace expansion, tilde expansion, parameter expansion, command substitution, arithmetic expansion, word splitting, filename expansion, and quote removal.

---

## Brace Expansion

Generate text patterns.

```bash
echo file{1..5}.txt
```

Output:

```text
file1.txt
file2.txt
file3.txt
file4.txt
file5.txt
```

---

## Tilde Expansion

```bash
echo ~
```

Output:

```text
/home/user
```

---

## Variable Expansion

```bash
name="John"

echo $name
```

Output:

```text
John
```

---

## Command Substitution

Execute a command and use its output.

```bash
current_date=$(date)
```

Example:

```bash
echo "Today is $current_date"
```

---

## Arithmetic Expansion

```bash
echo $((5 + 3))
```

Output:

```text
8
```

---

## Word Splitting

Bash splits unquoted text based on spaces.

Example:

```bash
name="John Doe"

echo $name
```

Becomes:

```text
John
Doe
```

To prevent splitting:

```bash
echo "$name"
```

---

## Filename Expansion (Globbing)

Match files using patterns.

```bash
ls *.txt
```

Examples:

```bash
*.txt
```

```bash
*.log
```

```bash
data-*
```

---

## Expansion Order

Bash processes expansions in a specific order. Understanding this explains many seemingly strange shell behaviors.

---

# 2.6 User Input

## read

Basic input:

```bash
read name
```

---

## Prompt Messages

```bash
read -p "Enter your name: " name
```

---

## Secure Password Input

Hide input:

```bash
read -s password
```

Example:

```bash
read -sp "Password: " password
```

---

# 2.7 Command Line Arguments

Arguments are passed when executing a script.

Example:

```bash
./script.sh hello world
```

---

## $0

Script name:

```bash
echo "$0"
```

---

## $1, $2

Arguments:

```bash
echo "$1"
echo "$2"
```

---

## $#

Argument count:

```bash
echo "$#"
```

---

## $@

All arguments:

```bash
echo "$@"
```

---

## $*

All arguments as a single string:

```bash
echo "$*"
```

---

## shift

Remove the first argument.

```bash
shift
```

Useful for argument parsing.

---

# 2.8 Arithmetic Operations

## Arithmetic Expansion

```bash
echo $((10 + 5))
```

---

## let

```bash
let result=10+5
```

---

## expr

```bash
expr 10 + 5
```

---

## Increment and Decrement

```bash
count=0

((count++))
```

```bash
((count--))
```

---

## Integer Limitations

Bash arithmetic only supports integers.

Example:

```bash
echo $((5 / 2))
```

Output:

```text
2
```

For floating-point calculations, use external tools:

```bash
echo "5 / 2" | bc -l
```

---

# Summary

In this chapter, you learned:

* How Bash executes commands
* Variables and special parameters
* Script structure
* Quoting rules
* Shell expansions
* User input
* Command-line arguments
* Arithmetic operations

These concepts form the foundation for everything that follows. Understanding expansion, quoting, and variable handling is essential before moving to control flow and functions.
