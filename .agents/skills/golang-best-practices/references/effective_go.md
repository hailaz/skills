# Effective Go — Extended Reference

Source: https://go.dev/doc/effective_go

## Introduction

Go is a new language. Although it borrows ideas from existing languages, it has unusual properties that make effective Go programs different in character from programs written in its relatives. A straightforward translation of a C++ or Java program into Go is unlikely to produce a satisfactory result — Java programs are written in Java, not Go. To write Go well, understand its properties and idioms and the established conventions for naming, formatting, and program construction.

## Formatting

All Go code should be formatted with `gofmt`. Rules:

- **Tabs** for indentation. `gofmt` emits tabs by default.
- **No line length limit**. Wrap long lines and indent with an extra tab.
- **Fewer parentheses** than C/Java. Operator precedence is clearer: `x<<8 + y<<16` means what the spacing implies.
- `gofmt` aligns struct field comments:

```go
type T struct {
    name    string // name of the object
    value   int    // its value
}
```

Use `goimports` (enhanced `gofmt`) to also manage import statements automatically.

## Commentary

### Package Comments

Every package should have a package comment preceding the `package` clause:

```go
/*
Package regexp implements a simple library for regular expressions.

The syntax of the regular expressions accepted is:
    regexp:
        concatenation { '|' concatenation }
*/
package regexp
```

Or briefly: `// Package path implements utility routines for manipulating slash-separated paths.`

### Doc Comments

Every exported name should have a doc comment starting with the name:

```go
// Compile parses a regular expression and returns, if successful,
// a Regexp that can be used to match against text.
func Compile(str string) (*Regexp, error) {
```

Group related declarations:

```go
// Error codes returned by failures to parse an expression.
var (
    ErrInternal      = errors.New("regexp: internal error")
    ErrUnmatchedLpar = errors.New("regexp: unmatched '('")
)
```

## Names

### Package Names

- Short, concise, lowercase, single-word: `time`, `list`, `http`.
- No underscores or mixedCaps.
- The package name is the accessor: `bufio.Reader` not `bufio.BufReader`.
- Constructors: `ring.New` for single-type packages; `NewReader`/`NewWriter` for multi-type.

### Getters — No `Get` prefix

```go
func (o *Object) Owner() string   { return o.owner }  // NOT GetOwner()
func (o *Object) SetOwner(n string) { o.owner = n }
```

### Interface Names — `-er` suffix

One-method interfaces: `Reader`, `Writer`, `Formatter`, `CloseNotifier`.
Honor canonical names: `Read`, `Write`, `Close`, `Flush`, `String`.

### MixedCaps

- `MixedCaps` (exported) / `mixedCaps` (unexported). Never underscores.
- Acronyms all caps: `URL`, `HTTP`, `ID`, `ServeHTTP`, `xmlHTTPRequest`.

## Semicolons

Lexer auto-inserts semicolons. Key rule: opening brace MUST be on same line as condition:

```go
if i < f() {  // Correct
    g()
}
```

## Control Structures

### If — Init statement and early return

```go
if err := file.Chmod(0664); err != nil {
    log.Print(err)
    return err
}
```

Drop `else` when body ends in `return`/`break`/`continue`/`goto`:

```go
f, err := os.Open(name)
if err != nil {
    return err
}
codeUsing(f)
```

### Redeclaration

`:=` allows reusing variables if at least one new var is declared:

```go
f, err := os.Open(name)
d, err := f.Stat()  // err reassigned, d is new
```

### For — Unified loop

```go
for init; condition; post { }  // C for
for condition { }              // C while
for { }                        // infinite

for key, value := range oldMap { newMap[key] = value }
for key := range m { }                       // keys only
for _, value := range array { sum += value }  // values only

// Parallel assignment for multiple variables
for i, j := 0, len(a)-1; i < j; i, j = i+1, j-1 {
    a[i], a[j] = a[j], a[i]
}
```

String `range` iterates by UTF-8 rune, not byte.

### Switch

No automatic fall through. Cases can be comma-separated. No-expression switch = `switch true`:

```go
switch {
case '0' <= c && c <= '9': return c - '0'
case 'a' <= c && c <= 'f': return c - 'a' + 10
}
```

Use labels to break out of surrounding loops from within a switch:

```go
Loop:
    for n := 0; n < len(src); n += size {
        switch {
        case src[n] < sizeOne:
            size = 1
        case src[n] < sizeTwo:
            if n+1 >= len(src) {
                break Loop
            }
        }
    }
```

### Type Switch

```go
switch t := value.(type) {
case string:  fmt.Printf("string: %s\n", t)
case int:     fmt.Printf("int: %d\n", t)
default:      fmt.Printf("unexpected type %T\n", t)
}
```

## Functions

### Multiple Return Values

```go
func nextInt(b []byte, i int) (int, int) { ... }
func (file *File) Write(b []byte) (n int, err error) { ... }
```

### Named Result Parameters

Initialized to zero values. Bare `return` uses current values:

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

LIFO order. Arguments evaluated at `defer` time, not call time:

```go
func Contents(filename string) (string, error) {
    f, err := os.Open(filename)
    if err != nil { return "", err }
    defer f.Close()
    // ... read f ...
    return string(result), nil
}

for i := 0; i < 5; i++ {
    defer fmt.Printf("%d ", i)  // Prints: 4 3 2 1 0
}
```

## Data

### `new` vs `make`

- `new(T)` — allocates zeroed `*T`. Use for any type.
- `make(T, args)` — initializes slices, maps, channels. Returns `T` (not pointer).

```go
p := new(SyncedBuffer)  // *SyncedBuffer, zero-valued, ready to use
v := make([]int, 100)   // []int, length & capacity 100
m := make(map[string]int)
ch := make(chan int, 10) // buffered channel
```

Zero-value usefulness: `bytes.Buffer` and `sync.Mutex` work without initialization.

### Composite Literals

```go
return &File{fd: fd, name: name}  // fields by name, order doesn't matter
a := [...]string{Enone: "no error", Eio: "Eio", Einval: "invalid argument"}
```

### Slices over Arrays

Arrays are values (copy on assign/pass). Slices wrap arrays flexibly. Use `append`:

```go
slice = append(slice, elem1, elem2)
slice = append(slice, anotherSlice...)
```

### Maps

Reference type. Comma-ok idiom:

```go
value, ok := m[key]
delete(m, key)
```

### Printing

`%v` default, `%+v` with field names, `%#v` Go syntax, `%T` type:

```go
fmt.Printf("%v\n", timeZone)    // map[CST:-21600 ...]
fmt.Printf("%+v\n", t)          // {Name:Alice Age:30}
fmt.Printf("%#v\n", t)          // main.Person{Name:"Alice", Age:30}
```

Custom format via `String() string`. Avoid infinite recursion in `Sprintf`.

## Initialization

### Constants with `iota`

```go
type ByteSize float64
const (
    _           = iota
    KB ByteSize = 1 << (10 * iota)
    MB
    GB
    TB
)
```

### `init` Functions

Each file can have multiple `init()`. Called after all var initializers and imports. Use for setup/validation.

## Methods — Pointers vs Values

- Value receivers: operate on copy, cannot modify original.
- Pointer receivers: modify original.
- Value methods callable on both pointers and values.
- Pointer methods callable only on addressable values (pointers).
- Rule of thumb: **if in doubt, use a pointer receiver**.

## Interfaces

- Implicitly satisfied — no `implements` keyword.
- Keep small: 1-3 methods. Key interfaces: `io.Reader`, `io.Writer`, `fmt.Stringer`, `error`.
- Type assertions: use comma-ok form `str, ok := val.(string)`.
- Export interfaces, not concrete types, when only interface methods matter.

## Blank Identifier

```go
_, err := os.Stat(path)             // discard first return value
import _ "net/http/pprof"            // side-effect import
var _ json.Marshaler = (*T)(nil)     // compile-time interface check
```

## Embedding

Embed types to "borrow" methods without subclassing:

```go
type ReadWriter struct {
    *Reader
    *Writer
}
```

Outer names shadow inner. Conflicts at same level error only if accessed.

## Concurrency

### Share by Communicating

> Do not communicate by sharing memory; instead, share memory by communicating.

### Goroutines

```go
go list.Sort()
go func() { /* ... */ }()
```

### Channels

```go
ci := make(chan int)           // unbuffered
cs := make(chan *os.File, 100) // buffered
```

Unbuffered = synchronization point. Buffered = semaphore:

```go
var sem = make(chan int, MaxOutstanding)
func handle(r *Request) {
    sem <- 1; process(r); <-sem
}
```

Channels of channels for demultiplexing. `select` for multiplexing.

### Leaky Buffer Pattern

```go
var freeList = make(chan *Buffer, 100)
select {
case b = <-freeList: // reuse
default: b = new(Buffer) // allocate
}
```

## Errors

- Return as last value: `func Open(name string) (*File, error)`.
- Always check. Include context: `fmt.Errorf("op %s: %w", name, err)`.
- Custom types: implement `Error() string` and `Unwrap() error`.
- Use `errors.Is`/`errors.As` for matching.

### Panic and Recover

- `panic`: unrecoverable errors only. Libraries should return errors.
- `recover`: inside deferred functions. Convert panics to errors at package boundaries:

```go
func (p *Parser) Parse(input string) (result *Tree, err error) {
    defer func() {
        if r := recover(); r != nil {
            err = fmt.Errorf("parse error: %v", r)
        }
    }()
    return p.parse(input), nil
}
```
