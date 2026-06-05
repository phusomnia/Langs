# 3. Control Flow

Control flow determines how a script makes decisions and repeats tasks.

Without control flow, Bash scripts execute commands sequentially from top to bottom.

Control flow allows scripts to:

* Make decisions_
* Execute different code paths
* Repeat operations
* Skip unnecessary work
* Build complex automation workflows

---

# 3.1 Conditional Statements

Conditional statements allow scripts to execute code only when certain conditions are met.

---

## Basic if Statement

Syntax:

```bash
if condition
then
    commands
fi
```

Example:

```bash
age=20

if [ "$age" -ge 18 ]; then
    echo "Adult"
fi
```

Output:

```text
Adult
```

---

## if-else

Execute one block when a condition is true and another when it is false.

```bash
age=15

if [ "$age" -ge 18 ]; then
    echo "Adult"
else
    echo "Minor"
fi
```

Output:

```text
Minor
```

---

## elif

Handle multiple conditions.

```bash
score=75

if [ "$score" -ge 90 ]; then
    echo "A"
elif [ "$score" -ge 80 ]; then
    echo "B"
elif [ "$score" -ge 70 ]; then
    echo "C"
else
    echo "F"
fi
```

Output:

```text
C
```

---

## Nested Conditions

Conditions can be nested.

```bash
age=25
country="US"

if [ "$age" -ge 18 ]; then
    if [ "$country" = "US" ]; then
        echo "Allowed"
    fi
fi
```

Although possible, excessive nesting reduces readability.

Prefer:

```bash
if [ "$age" -ge 18 ] && [ "$country" = "US" ]; then
    echo "Allowed"
fi
```

---

# 3.2 Test Expressions

Conditions rely on test expressions.

Bash provides:

```bash
[ ]
```

and

```bash
[[ ]]
```

For modern Bash scripts, `[[ ]]` is generally preferred because it provides safer parsing and additional features.

---

## Using [ ]

Traditional syntax:

```bash
if [ "$age" -gt 18 ]; then
    echo "Adult"
fi
```

---

## Using [[ ]]

Modern syntax:

```bash
if [[ $age -gt 18 ]]; then
    echo "Adult"
fi
```

Advantages:

* Better handling of spaces
* Pattern matching support
* Regex support
* Safer comparisons

---

## String Comparisons

Equality:

```bash
name="John"

if [[ "$name" == "John" ]]; then
    echo "Match"
fi
```

Not equal:

```bash
if [[ "$name" != "John" ]]; then
    echo "Different"
fi
```

Empty string:

```bash
if [[ -z "$name" ]]; then
    echo "Empty"
fi
```

Non-empty string:

```bash
if [[ -n "$name" ]]; then
    echo "Has value"
fi
```

---

## Numeric Comparisons

| Operator | Meaning               |
| -------- | --------------------- |
| -eq      | Equal                 |
| -ne      | Not equal             |
| -gt      | Greater than          |
| -ge      | Greater than or equal |
| -lt      | Less than             |
| -le      | Less than or equal    |

Example:

```bash
count=10

if [[ $count -gt 5 ]]; then
    echo "Large"
fi
```

---

## File Tests

Check file existence:

```bash
if [[ -f config.json ]]; then
    echo "File exists"
fi
```

Check directory:

```bash
if [[ -d logs ]]; then
    echo "Directory exists"
fi
```

Check executable:

```bash
if [[ -x script.sh ]]; then
    echo "Executable"
fi
```

Common file operators:

| Operator | Description    |
| -------- | -------------- |
| -f       | Regular file   |
| -d       | Directory      |
| -e       | Exists         |
| -r       | Readable       |
| -w       | Writable       |
| -x       | Executable     |
| -s       | Non-empty file |

---

## Logical Operators

AND:

```bash
if [[ $age -gt 18 && $country == "US" ]]; then
    echo "Allowed"
fi
```

OR:

```bash
if [[ $role == "admin" || $role == "manager" ]]; then
    echo "Authorized"
fi
```

NOT:

```bash
if [[ ! -f config.json ]]; then
    echo "Missing"
fi
```

---

# 3.3 Case Statements

Case statements provide an alternative to long chains of `if-elif`.

---

## Basic Case Statement

```bash
read -p "Command: " command

case "$command" in
    start)
        echo "Starting"
        ;;
    stop)
        echo "Stopping"
        ;;
    restart)
        echo "Restarting"
        ;;
    *)
        echo "Unknown command"
        ;;
esac
```

---

## Pattern Matching

Case statements support wildcard patterns.

Example:

```bash
file="notes.txt"

case "$file" in
    *.txt)
        echo "Text file"
        ;;
    *.log)
        echo "Log file"
        ;;
    *)
        echo "Unknown"
        ;;
esac
```

Output:

```text
Text file
```

---

## Multiple Matches

```bash
case "$option" in
    y|Y|yes|YES)
        echo "Confirmed"
        ;;
    n|N|no|NO)
        echo "Rejected"
        ;;
esac
```

---

# 3.4 Loops

Loops repeat commands.

Bash provides:

* for
* while
* until

---

## for Loop

Iterate over a list.

```bash
for fruit in apple banana orange
do
    echo "$fruit"
done
```

Output:

```text
apple
banana
orange
```

---

## Numeric for Loop

```bash
for i in {1..5}
do
    echo "$i"
done
```

Output:

```text
1
2
3
4
5
```

Brace expansion occurs before execution and generates the sequence automatically.

---

## C-Style for Loop

```bash
for ((i=1; i<=5; i++))
do
    echo "$i"
done
```

Output:

```text
1
2
3
4
5
```

---

## Looping Through Files

```bash
for file in *.txt
do
    echo "$file"
done
```

Bash expands the wildcard before entering the loop.

---

## while Loop

Execute while a condition remains true.

```bash
count=1

while [[ $count -le 5 ]]
do
    echo "$count"
    ((count++))
done
```

Output:

```text
1
2
3
4
5
```

---

## Reading Files with while

Common production pattern:

```bash
while read -r line
do
    echo "$line"
done < users.txt
```

The `-r` option prevents backslash interpretation.

---

## Infinite while Loop

```bash
while true
do
    echo "Running..."
done
```

Terminate using:

```text
Ctrl + C
```

---

## until Loop

Execute until a condition becomes true.

```bash
count=1

until [[ $count -gt 5 ]]
do
    echo "$count"
    ((count++))
done
```

Output:

```text
1
2
3
4
5
```

Think of `until` as the opposite of `while`.

---

## break

Exit a loop immediately.

```bash
for i in {1..10}
do
    if [[ $i -eq 5 ]]; then
        break
    fi

    echo "$i"
done
```

Output:

```text
1
2
3
4
```

---

## continue

Skip the current iteration.

```bash
for i in {1..5}
do
    if [[ $i -eq 3 ]]; then
        continue
    fi

    echo "$i"
done
```

Output:

```text
1
2
4
5
```

---

## Nested Loops

```bash
for row in {1..3}
do
    for col in {1..3}
    do
        echo "$row,$col"
    done
done
```

Output:

```text
1,1
1,2
1,3
2,1
...
```

---

# Common Control Flow Patterns

## Input Validation

```bash
read -p "Age: " age

if [[ ! $age =~ ^[0-9]+$ ]]; then
    echo "Invalid age"
    exit 1
fi
```

---

## Retry Loop

```bash
attempt=1

while [[ $attempt -le 3 ]]
do
    if curl -s https://example.com > /dev/null; then
        echo "Success"
        break
    fi

    ((attempt++))
done
```

---

## Menu System

```bash
while true
do
    echo "1. Start"
    echo "2. Stop"
    echo "3. Exit"

    read -p "Choice: " choice

    case "$choice" in
        1)
            echo "Starting..."
            ;;
        2)
            echo "Stopping..."
            ;;
        3)
            exit 0
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
done
```

---

# Summary

In this chapter, you learned:

* Conditional statements (`if`, `else`, `elif`)
* Test expressions (`[ ]`, `[[ ]]`)
* String, numeric, and file comparisons
* Logical operators
* Case statements
* `for`, `while`, and `until` loops
* `break` and `continue`
* Common control flow patterns

Control flow allows Bash scripts to make decisions and repeat operations. Combined with variables and shell expansion from the previous chapter, it provides the foundation for writing practical automation scripts.
