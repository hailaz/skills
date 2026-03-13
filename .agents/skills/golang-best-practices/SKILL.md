---
name: golang-best-practices
description: "This skill provides Go (Golang) programming best practices based on the official Effective Go document. It should be used when writing, reviewing, or refactoring Go code to ensure it follows idiomatic Go patterns and conventions. Triggers include: writing new Go files, reviewing Go code quality, asking about Go coding style, naming conventions, error handling patterns, concurrency patterns, or any Go-specific best practice questions."
---

# Golang Best Practices (Effective Go)

## Overview

This skill encapsulates the official Go programming best practices from the [Effective Go](https://go.dev/doc/effective_go) document. It provides guidance on writing clear, idiomatic Go code that follows the conventions and patterns established by the Go community. Apply these guidelines when writing new Go code, reviewing existing code, or refactoring Go projects.

> To write Go well, understand its properties and idioms. Know the established conventions for programming in Go — naming, formatting, program construction — so that programs written by other Go programmers will be easy to understand.

## Formatting

- Always use `gofmt` (or `goimports`) to format Go source code. Do not argue about formatting — let the tool handle it.
- `gofmt` handles indentation (tabs), alignment, and spacing automatically.
- Go uses **tabs for indentation** and `gofmt` emits them by default.
- Go has **no line length limit**; if a line feels too long, wrap it and indent with an extra tab.
- Go requires **fewer parentheses** than C/Java — control structures (`if`, `for`, `switch`) do not require parentheses around conditions.

## Commentary

- Go uses C-style `/* */` block comments and C++-style `//` line comments.
- Line comments (`//`) are the norm; block comments appear mostly as package comments or to disable code.
- **Package comments**: Every package should have a package comment — a block comment preceding the `package` clause. For multi-file packages, the package comment only needs to be in one file.
- **Doc comments**: Comments directly preceding a top-level declaration serve as documentation for that item. Every exported (capitalized) name should have a doc comment.
- Write doc comments as **complete sentences**, starting with the name being declared:

```go
// Compile parses a regular expression and returns, if successful,
// a Regexp object that can be used to match against text.
func Compile(str string) (*Regexp, error) {
```

- Use `godoc` style — the first sentence appears in lists as a summary.
- For grouping declarations, use a single doc comment to introduce related constants or variables:

```go
// Error codes returned by failures to parse an expression.
var (
    ErrInternal      = errors.New("regexp: internal error")
    ErrUnmatchedLpar = errors.New("regexp: unmatched '('")
)
```

## Names

### Package Names

- Package names should be **short, concise, lowercase, single-word** names with no underscores or mixedCaps.
- The package name is the base name of its source directory (e.g., package in `src/encoding/base64` is imported as `"encoding/base64"` but named `base64`).
- The importer uses the package name to refer to contents, so exported names in the package can use that to avoid stutter. For example, use `ring.New` instead of `ring.NewRing`.
- Read other packages for good naming examples: `bufio.Reader`, not `bufio.BufReader`.

### Getters and Setters

- Go does not provide automatic getter/setter support but it's fine to write them.
- An unexported field `owner` should have getter `Owner()` (uppercase, no `Get` prefix), not `GetOwner()`.
- The setter function, if needed, should be called `SetOwner()`:

```go
owner := obj.Owner()
if owner != user {
    obj.SetOwner(user)
}
```

### Interface Names

- One-method interfaces are named by the **method name plus an `-er` suffix** (or similar): `Reader`, `Writer`, `Formatter`, `CloseNotifier`.
- Honor established names: `Read`, `Write`, `Close`, `Flush`, `String` etc. — give methods the same signature and meaning.

### MixedCaps

- Go convention is to use **MixedCaps** or **mixedCaps** rather than underscores for multi-word names.
- Exported names start with an uppercase letter (`MixedCaps`); unexported names start with a lowercase letter (`mixedCaps`).
- Acronyms should be **all caps**: `URL`, `HTTP`, `ID` — e.g., `ServeHTTP`, `htmlEscape`, `URLPath`.

## Semicolons

- Go's lexer automatically inserts semicolons; do not use them explicitly except in `for` loop clauses and to separate multiple statements on a line.
- **Consequence**: never put the opening brace of a control structure on the next line:

```go
// Correct
if i < f() {
    g()
}

// WRONG — will not compile
if i < f()
{           // WRONG!
    g()
}
```

## Control Structures

### If

- Accept an initialization statement; prefer keeping the happy path unindented:

```go
f, err := os.Open(name)
if err != nil {
    return err
}
// use f — f is in scope here
```

- When an `if` statement doesn't flow into the next statement (ends in `break`, `continue`, `return`, or `goto`), drop the unnecessary `else`:

```go
// Good
f, err := os.Open(name)
if err != nil {
    return err
}
d, err := f.Stat()
if err != nil {
    f.Close()
    return err
}
// use f and d
```

### For

- Go's `for` unifies C's `for`, `while`, and `do-while`:

```go
// Like a C for
for init; condition; post { }

// Like a C while
for condition { }

// Like a C for(;;) / infinite loop
for { }
```

- Use `range` to iterate over arrays, slices, strings, maps, and channels:

```go
for key, value := range oldMap {
    newMap[key] = value
}
```

- Use blank identifier `_` to discard unwanted values:

```go
for _, value := range array {
    // use value only
}
```

### Switch

- Go's switch is more flexible than C's — expressions need not be constants or integers.
- Cases evaluate top to bottom; there is **no automatic fall through** (use `fallthrough` keyword if needed).
- Cases can be presented in comma-separated lists:

```go
func shouldEscape(c byte) bool {
    switch c {
    case ' ', '?', '&', '=', '#', '+', '%':
        return true
    }
    return false
}
```

- A switch with no expression is equivalent to `switch true` — an `if-else-if-else` chain:

```go
func unhex(c byte) byte {
    switch {
    case '0' <= c && c <= '9':
        return c - '0'
    case 'a' <= c && c <= 'f':
        return c - 'a' + 10
    case 'A' <= c && c <= 'F':
        return c - 'A' + 10
    }
    return 0
}
```

### Type Switch

- Use type switch to discover the dynamic type of an interface variable:

```go
switch v := value.(type) {
case string:
    fmt.Printf("string: %s\n", v)
case int:
    fmt.Printf("int: %d\n", v)
default:
    fmt.Printf("unexpected type %T\n", v)
}
```

## Functions

### Multiple Return Values

- Go functions can return multiple values. Use this for error indication:

```go
func nextInt(b []byte, i int) (int, int) {
    for ; i < len(b) && isDigit(b[i]); i++ {
    }
    x := 0
    // ... parse integer ...
    return x, i
}
```

### Named Result Parameters

- Return parameters can be named and used as regular variables. When named, they are initialized to zero values upon function entry:

```go
func ReadFull(r Reader, buf []byte) (n int, err error) {
    for len(buf) > 0 && err == nil {
        var nr int
        nr, err = r.Read(buf)
        n += nr
        buf = buf[nr:]
    }
    return
}
```

### Defer

- `defer` schedules a function call to run after the function returns. Use for cleanup:

```go
func Contents(filename string) (string, error) {
    f, err := os.Open(filename)
    if err != nil {
        return "", err
    }
    defer f.Close()

    var result []byte
    // ... read file ...
    return string(result), nil
}
```

- Deferred functions execute in **LIFO order**.
- Arguments to deferred functions are evaluated when the `defer` executes, not when the function runs.

## Data

### Allocation with `new` and `make`

- **`new(T)`** allocates zeroed storage for a new item of type `T` and returns `*T`. It does not initialize memory, only zeros it.
- **`make(T, args)`** creates slices, maps, and channels only, and returns an initialized (not zeroed) value of type `T` (not `*T`).
- `new` returns a pointer; `make` returns the type directly:

```go
p := new(SyncedBuffer)  // type *SyncedBuffer, zeroed, ready to use
v := make([]int, 10)    // type []int, length 10, capacity 10
```

### Composite Literals

- Use composite literals to create instances with field values:

```go
return &File{fd: fd, name: name}
```

- The fields of a composite literal are laid out in order and must all be present when field names are omitted; using field names permits any order and absent fields get zero values.

### Arrays and Slices

- Arrays are values in Go — assigning an array copies all elements. Passing an array to a function passes a copy.
- **Prefer slices over arrays** — slices wrap arrays to give a more flexible interface.
- Use `append` to grow slices:

```go
func Append(slice, data []byte) []byte {
    l := len(slice)
    if l+len(data) > cap(slice) {
        newSlice := make([]byte, (l+len(data))*2)
        copy(newSlice, slice)
        slice = newSlice
    }
    slice = slice[0 : l+len(data)]
    copy(slice[l:], data)
    return slice
}
```

### Maps

- Maps hold references; passing a map to a function and changing the map's contents is visible to the caller.
- Use comma-ok idiom to test existence:

```go
value, ok := timeZone[tz]
if !ok {
    // tz is not in the map
}
```

- Delete a map entry with `delete(map, key)`.

### Printing

- Use `fmt.Printf` (formatted), `fmt.Println` (with spaces and newline), `fmt.Print` (default formats).
- `%v` prints any value in a default format; `%+v` annotates struct fields with names; `%#v` prints full Go syntax:

```go
fmt.Printf("%v\n", timeZone)   // map[CST:-21600 EST:-18000 ...]
fmt.Printf("%+v\n", t)         // {Name:Alice Age:30}
fmt.Printf("%#v\n", t)         // main.Person{Name:"Alice", Age:30}
```

- Implement the `String() string` method to define a custom default format for a type.
- **Caution**: Do not construct a `String` method by calling `Sprintf` in a way that recurs indefinitely:

```go
// WRONG — will recur infinitely
func (m MyString) String() string {
    return fmt.Sprintf("MyString=%s", m) // calls String() again!
}

// CORRECT
func (m MyString) String() string {
    return fmt.Sprintf("MyString=%s", string(m)) // convert to string first
}
```

## Initialization

### Constants

- Constants are created at compile time and can only be numbers, characters (runes), strings, or booleans.
- Use `iota` enumerator for creating enumerated constants:

```go
type ByteSize float64
const (
    _           = iota // ignore first value by assigning to blank identifier
    KB ByteSize = 1 << (10 * iota)
    MB
    GB
    TB
)
```

### Variables

- Variables can be initialized like constants but with the value computed at run time:

```go
var (
    home   = os.Getenv("HOME")
    user   = os.Getenv("USER")
    gopath = os.Getenv("GOPATH")
)
```

### The `init` Function

- Each source file can define one or more `init` functions to set up state before execution begins.
- `init` is called after all variable declarations evaluate their initializers and after all imported packages have been initialized.
- Common use: verify or repair correctness of program state before real execution begins.

## Methods

### Pointers vs. Values

- Methods can be defined on any named type (except pointers and interfaces).
- **Value receivers**: method operates on a copy; cannot modify the original.
- **Pointer receivers**: method can modify the original value.
- Rule of thumb: **if in doubt, use a pointer receiver**.
- The rule: value methods can be invoked on pointers and values; pointer methods can only be invoked on pointers:

```go
type ByteSlice []byte

// Value receiver — gets a copy
func (slice ByteSlice) Len() int {
    return len(slice)
}

// Pointer receiver — modifies original
func (p *ByteSlice) Append(data []byte) {
    *p = append(*p, data...)
}
```

## Interfaces and Other Types

### Interfaces

- Go interfaces are satisfied implicitly — no `implements` keyword needed.
- A type can implement multiple interfaces.
- Keep interfaces **small and focused**: prefer many small interfaces (1-3 methods) over large ones.
- The most important interfaces: `io.Reader`, `io.Writer`, `fmt.Stringer`, `error`.

### Type Conversions and Assertions

- **Type conversion**: converts a value to a different type — `string(byteSlice)`.
- **Type assertion**: extracts the concrete value from an interface — `value.(Type)`:

```go
str, ok := value.(string)
if ok {
    fmt.Printf("string value is: %q\n", str)
}
```

- Always use the comma-ok form to avoid panics on failed assertions.

### Generality

- If a type exists only to implement an interface and will never have exported methods beyond that interface, export the interface, not the type.
- Constructors should return an interface value rather than the implementing type when only the interface methods matter.

## The Blank Identifier

- The blank identifier `_` can be assigned any value of any type and the value is discarded.
- Use in multiple assignment to discard unwanted values:

```go
if _, err := os.Stat(path); os.IsNotExist(err) {
    // path does not exist
}
```

- Use for **unused imports** during development (remove before final code):

```go
import _ "net/http/pprof" // side-effect import
```

- Use for **interface compliance checks** at compile time:

```go
var _ json.Marshaler = (*RawMessage)(nil)
```

## Embedding

- Go does not have subclassing, but can "borrow" pieces of an implementation by embedding types within structs or interfaces.
- Embed an interface to indicate the methods it should satisfy; embed a struct to gain its methods:

```go
type ReadWriter struct {
    *Reader  // embedded — *ReadWriter gains Reader methods
    *Writer  // embedded — *ReadWriter gains Writer methods
}
```

- Embedding differs from subclassing: when a method of an embedded type is invoked, the receiver is the embedded field, not the outer struct.
- Embedding creates **naming conflicts** — outer names take precedence. If two embedded fields have the same name at the same level, it causes an error only if the name is used.

## Concurrency

### Share by Communicating

> Do not communicate by sharing memory; instead, share memory by communicating.

- This is Go's key concurrency philosophy. Use channels to pass data between goroutines instead of using mutexes to protect shared data.
- The model: one goroutine has access to a value at a time; data races cannot occur by design.

### Goroutines

- Goroutines are lightweight: they cost little more than stack space allocation.
- Launch a goroutine with the `go` keyword:

```go
go list.Sort()  // run list.Sort concurrently

// Function literal in a goroutine
go func() {
    // do work
}()
```

### Channels

- Allocate channels with `make`:

```go
ci := make(chan int)            // unbuffered channel of integers
cs := make(chan *os.File, 100)  // buffered channel of file pointers
```

- Unbuffered channels combine communication with synchronization — the sender blocks until the receiver has received the value.
- Use buffered channels as semaphores to limit throughput:

```go
var sem = make(chan int, MaxOutstanding)

func handle(r *Request) {
    sem <- 1    // wait for active queue to drain
    process(r)
    <-sem       // done; enable next request to run
}
```

### Channels of Channels

- Channels are first-class values and can be sent over channels themselves. Use this pattern for demultiplexing:

```go
type Request struct {
    args       []int
    resultChan chan int
}
```

### Parallelization

- Use goroutines to parallelize computation across CPU cores:

```go
func DoAll(items []Item) {
    done := make(chan bool, len(items))
    for _, item := range items {
        go func(it Item) {
            Process(it)
            done <- true
        }(item)
    }
    for range items {
        <-done
    }
}
```

- Set `GOMAXPROCS` or use `runtime.NumCPU()` to control parallelism (default uses all available CPUs since Go 1.5).

### A Leaky Buffer Example

- Use buffered channels as free lists to avoid allocations:

```go
var freeList = make(chan *Buffer, 100)
var serverChan = make(chan *Buffer)

func server() {
    for {
        var b *Buffer
        select {
        case b = <-freeList:
            // got one; nothing more to do
        default:
            b = new(Buffer) // none free, allocate a new one
        }
        process(b)
        select {
        case freeList <- b:
            // reuse buffer if room
        default:
            // free list full, just carry on
        }
    }
}
```

## Errors

### Error Handling Patterns

- In Go, errors are values of type `error`. Return errors as the last return value:

```go
func Open(name string) (file *File, err error)
```

- **Always check errors** — never ignore returned error values.
- Create descriptive error messages that identify the operation and the failing input:

```go
return nil, fmt.Errorf("crypto/rsa: decryption error (label too long: %d)", len(label))
```

- Callers that need to distinguish specific errors can use type assertions or `errors.Is`/`errors.As`:

```go
if errors.Is(err, os.ErrNotExist) {
    // handle missing file
}
```

### Custom Error Types

- Implement the `error` interface for custom error types providing more context:

```go
type PathError struct {
    Op   string
    Path string
    Err  error
}

func (e *PathError) Error() string {
    return e.Op + " " + e.Path + ": " + e.Err.Error()
}

func (e *PathError) Unwrap() error {
    return e.Err
}
```

### Panic

- `panic` creates a run-time error that stops the program. Use it for truly unrecoverable situations:

```go
func MustCompile(str string) *Regexp {
    regexp, err := Compile(str)
    if err != nil {
        panic(`regexp: Compile(` + quote(str) + `): ` + err.Error())
    }
    return regexp
}
```

- Library functions should avoid calling `panic`; if the problem can be masked or worked around, let the caller handle it.
- Real library functions should avoid `panic` — prefer returning errors.

### Recover

- `recover` regains control of a panicking goroutine. It is only useful inside deferred functions:

```go
func safelyDo(work func()) {
    defer func() {
        if err := recover(); err != nil {
            log.Println("work failed:", err)
        }
    }()
    work()
}
```

- Use `recover` to convert internal panics into error return values at package boundaries:

```go
func (p *Parser) Parse(input string) (result *Tree, err error) {
    defer func() {
        if r := recover(); r != nil {
            err = fmt.Errorf("parse error: %v", r)
        }
    }()
    // ... parsing code that may panic ...
    return p.parse(input), nil
}
```

## Quick Reference: Idiomatic Go Checklist

When writing or reviewing Go code, verify:

1. **Formatting**: Code is `gofmt`-formatted.
2. **Naming**: Follows Go conventions — short package names, MixedCaps, no stuttering, `-er` interfaces.
3. **Error handling**: All errors are checked and handled; errors include context; no silent drops.
4. **Control flow**: Happy path is not indented; `else` after `return` is eliminated; early returns used.
5. **Functions**: Use multiple return values for error indication; use named returns judiciously; use `defer` for cleanup.
6. **Data structures**: Use `make` for slices/maps/channels; use `new` for zero-value pointers; prefer slices over arrays.
7. **Interfaces**: Small and focused; satisfied implicitly; use for abstraction boundaries.
8. **Concurrency**: Share by communicating; use channels for synchronization; avoid races by design.
9. **Panics**: Reserved for truly unrecoverable errors; libraries return errors instead.
10. **Comments**: All exported names have doc comments; package has a package comment.

## Resources

For the complete and most authoritative reference, consult the full Effective Go document:

- `references/effective_go.md` — Contains detailed explanations, extended examples, and additional context for all topics covered above. Grep for section headers (e.g., `## Formatting`, `## Concurrency`) to quickly locate specific guidance.

For further reading beyond Effective Go:

- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments) — Additional common review feedback
- [Go Proverbs](https://go-proverbs.github.io/) — Rob Pike's guiding principles
- [Standard library](https://pkg.go.dev/std) — The best examples of idiomatic Go
