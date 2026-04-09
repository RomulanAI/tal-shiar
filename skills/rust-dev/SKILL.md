---
name: rust-dev
description: Expert guidance on Rust programming — ownership, borrowing, lifetimes, Cargo, Rustup, common crates (tokio, serde, clap, reqwest, axum), async/await, traits, generics, macros, and systems programming patterns. Triggers when user asks about: Rust programming, Cargo, Rust ownership/borrowing, lifetimes, async Rust, tokio, serde, traits, structs, enums, or any aspect of Rust development.
---

# Rust Developer Skill

Rust is a systems programming language that guarantees memory safety without a garbage collector — zero-cost abstractions, fearless concurrency, and an expressive type system. This skill covers idiomatic Rust from ownership basics to async networking.

---

## 1. Rustup & Cargo

### Setup
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup update          # update stable
rustup install nightly # for nightly features
rustup default stable

# IDE support
rust-analyzer (VSCode "rust-analyzer" extension)
```

### Cargo Commands
```bash
cargo new myproject        # scaffold new project
cargo init                # init in existing dir
cargo build               # compile
cargo run                 # build + run
cargo test                # run tests
cargo test --lib          # lib tests only
cargo test -- --nocapture # see print output
cargo check              # type-check without generating binaries
cargo clippy             # linting (run before PR)
cargo fmt               # format code
cargo bench             # run benchmarks
cargo build --release   # optimized build
cargo doc --open        # generate + open docs

# Dependencies (Cargo.toml)
[dependencies]
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
clap = { version = "4", features = ["derive"] }
anyhow = "1"
thiserror = "1"
reqwest = { version = "0.12", features = ["json"] }
axum = "0.7"
tracing = "0.1"
```

---

## 2. Ownership & Borrowing — The Core

### The Three Rules
```rust
// Every value has exactly one owner
// When the owner goes out of scope, the value is dropped
// You can have either ONE mutable reference OR multiple immutable references

fn main() {
    let s1 = String::from("hello"); // s1 owns the string
    let s2 = s1;                    // ownership MOVES to s2
    // println!("{}", s1);          // ERROR: s1 no longer valid

    let s3 = String::from("world");
    let s4 = &s3;                   // immutable borrow
    println!("{} {}", s3, s4);       // OK: both valid

    let mut s5 = String::from("rust");
    let s6 = &mut s5;              // mutable borrow
    s6.push_str("ace");
    println!("{}", s6);
    // let s7 = &mut s5;           // ERROR: only one mutable ref at a time
}
```

### Borrowing Rules Summary
| Pattern | Syntax | Aliases | Can mutate? |
|---------|--------|---------|-------------|
| Immutable borrow | `&T` | reference | No |
| Mutable borrow | `&mut T` | exclusive reference | Yes |
| Move | `T` | ownership transfer | — |

### Lifetimes
```rust
// Lifetime elision (compiler infers in simple cases)
fn first_word(s: &str) -> &str {
    &s[..s.find(' ').unwrap_or(s.len())]
}

// Explicit lifetime annotation
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}

// Struct with lifetime
struct Excerpt<'a> {
    part: &'a str,  // must not outlive the source
}

impl<'a> Excerpt<'a> {
    fn new(article: &'a str) -> Self {
        Self { part: &article[..10] }
    }
}
```

### The Borrow Checker in Practice
```rust
// CLONE to avoid moves (expensive but safe)
let s1 = String::from("hello");
let s2 = s1.clone();    // deep copy, no move

// COPY for stack-only types (cheap, implicit)
let x = 5;
let y = x;              // i32 is Copy, x still valid

// DROPPING order matters
struct Person { name: String }
impl Drop for Person {
    fn drop(&mut self) { println!("Goodbye {}", self.name); }
}

// Rc<T> for shared ownership (reference counted)
use std::rc::Rc;
let s = Rc::new(String::from("shared"));
let s2 = Rc::clone(&s);  // cheap: increments ref count, not deep copy

// RefCell<T>: interior mutability (runtime borrow checking)
use std::cell::RefCell;
let data = RefCell::new(vec![1, 2, 3]);
data.borrow_mut().push(4);   // mutably borrow at runtime
```

---

## 3. Structs, Enums & Traits

### Structs
```rust
// Tuple struct
struct Point(f64, f64);

// Classic struct
struct Rectangle {
    width: u32,
    height: u32,
}

impl Rectangle {
    fn new(width: u32, height: u32) -> Self {
        Rectangle { width, height }
    }

    fn area(&self) -> u32 {
        self.width * self.height
    }

    // Associated function (no &self = constructor pattern)
    fn square(size: u32) -> Self {
        Self { width: size, height: size }
    }

    // Mutable method
    fn scale(&mut self, factor: u32) {
        self.width *= factor;
        self.height *= factor;
    }
}

// Struct update syntax
let r2 = Rectangle { width: 30, ..r1 }; // fill rest from r1
```

### Enums & Pattern Matching
```rust
enum Message {
    Quit,                           // unit variant
    Move { x: i32, y: i32 },       // struct variant
    Write(String),                  // tuple variant
    ChangeColor(u8, u8, u8),
}

fn process(msg: Message) {
    match msg {
        Message::Quit => println!("quit"),
        Message::Move { x, y } => println!("move to ({x}, {y})"),
        Message::Write(text) => println!("write: {text}"),
        Message::ChangeColor(r, g, b) => {
            println!("color: {r}, {g}, {b}")
        }
    }
}

// if let (partial match)
if let Message::Write(text) = msg {
    println!("Writing: {text}");
}

// Option (builtin enum)
enum Option<T> {
    Some(T),
    None,
}

fn find(map: &HashMap<String, i32>, key: &str) -> Option<&i32> {
    map.get(key)   // returns Option<&i32>
}
```

### Traits (Interfaces)
```rust
trait Summary {
    fn summarize(&self) -> String;

    // Default implementation
    fn default_summary(&self) -> String {
        String::from("(Read more...)")
    }
}

struct Article { title: String, author: String }

impl Summary for Article {
    fn summarize(&self) -> String {
        format!("{} by {}", self.title, self.author)
    }
}

// Trait bounds
fn notify(item: &impl Summary) {
    println!("Breaking: {}", item.summarize());
}

fn notify<T: Summary>(item: &T) { }    // equivalent

// where clause (cleaner for multiple bounds)
fn notify<T>(item: &T)
where
    T: Summary + Clone,
{ }

// blanket implementations
impl<T: Display + Clone> ToString for T {}

// Traits as parameters
fn returns_summarizable() -> impl Summary {
    Article { title: String::from("a"), author: String::from("b") }
}
```

---

## 4. Generics

```rust
// Generic struct
struct Stack<T> {
    items: Vec<T>,
}

impl<T> Stack<T> {
    fn push(&mut self, item: T) {
        self.items.push(item);
    }

    fn pop(&mut self) -> Option<T> {
        self.items.pop()
    }
}

// Generic functions
fn largest<T: PartialOrd>(list: &[T]) -> &T {
    let mut largest = &list[0];
    for item in list {
        if item > largest {
            largest = item;
        }
    }
    largest
}

// Multiple type parameters
fn pair<T, U>(a: T, b: U) -> (T, U) {
    (a, b)
}
```

---

## 5. Error Handling

### Result<T, E>
```rust
use std::fs::File;
use std::io::{self, Read};

// Propagating errors with ?
fn read_file(path: &str) -> Result<String, io::Error> {
    let mut file = File::open(path)?;  // ? returns early on Err
    let mut contents = String::new();
    file.read_to_string(&mut contents)?;
    Ok(contents)
}

// Anyhow (ergonomic errors)
use anyhow::{Context, Result};

fn read_config(path: &str) -> Result<Config> {
    let contents = std::fs::read_to_string(path)
        .with_context(|| format!("Failed to read {path}"))?;
    toml::from_str(&contents)
        .context("Failed to parse config")
}

// Thiserror (library errors)
use thiserror::Error;

#[derive(Error, Debug)]
enum ConfigError {
    #[error("file not found: {0}")]
    NotFound(String),
    #[error("parse error: {0}")]
    Parse(#[from] toml::de::Error),
}
```

### Panic & Unwrap
```rust
// Don't use unwrap in library code
let value = something_that_returns_option.unwrap();   // panics if None
let value = something_that_returns_option.unwrap_or(42);  // safe default
let value = something_that_returns_option.unwrap_or_else(default_fn);  // lazy

// expect (better error message)
let value = config.get("port").expect("port must be set");

// ? operator
let port = config.get("port")?.parse::<u16>()?;
```

---

## 6. Ownership Patterns for Common Cases

### Rc<RefCell<T>> (shared mutability)
```rust
use std::cell::RefCell;
use std::rc::Rc;

let shared = Rc::new(RefCell::new(vec![1, 2]));
let a = Rc::clone(&shared);
let b = Rc::clone(&shared);

// Multiple owners can mutate
a.borrow_mut().push(3);
b.borrow_mut().push(4);
println!("{:?}", shared.borrow()); // [1, 2, 3, 4]
```

### Interior Mutability (Cell, RefCell)
```rust
use std::cell::Cell;
use std::cell::RefCell;

let counter = Cell::new(0);
counter.set(counter.get() + 1);  // &self but mutable via Cell

let data = RefCell::new([1, 2, 3]);
let v = data.borrow();  // immutable borrow
let v2 = data.borrow();  // multiple immutable borrows OK
drop(v);                 // release borrow
data.borrow_mut()[0] = 5; // now mutable borrow works
```

### The Mutex (thread-safe interior mutability)
```rust
use std::sync::{Arc, Mutex};
use std::thread;

let counter = Arc::new(Mutex::new(0));
let handles: Vec<_> = (0..10).map(|_| {
    let counter = Arc::clone(&counter);
    thread::spawn(move || {
        let mut num = counter.lock().unwrap();
        *num += 1;
    })
}).collect();

for h in handles { h.join().unwrap(); }
println!("{}", *counter.lock().unwrap()); // 10
```

---

## 7. Async / Await & Tokio

### Basic Async
```rust
// Cargo.toml
// tokio = { version = "1", features = ["full"] }

#[tokio::main]
async fn main() {
    let handle = tokio::spawn(async {
        // concurrent task
        42
    });

    let result = handle.await.unwrap();
    println!("spawned task returned: {result}");

    // Join multiple futures
    let (a, b) = tokio::join!(fut_a(), fut_b());
}

// tokio::spawn returns JoinHandle<T>
let handle = tokio::spawn(async move {
    do_work().await
});
```

### Async Traits (object-safe)
```rust
use async_trait::async_trait;

#[async_trait]
trait Fetch {
    async fn fetch(&self, url: &str) -> anyhow::Result<String>;
}

struct HttpClient;
#[async_trait]
impl Fetch for HttpClient {
    async fn fetch(&self, url: &str) -> anyhow::Result<String> {
        Ok(reqwest::get(url).await?.text().await?)
    }
}
```

### Channels
```rust
use tokio::sync::mpsc;

#[tokio::main]
async fn main() {
    let (tx, mut rx) = mpsc::channel(32);

    tokio::spawn(async move {
        tx.send("hello").await.unwrap();
    });

    if let Some(msg) = rx.recv().await {
        println!("got: {msg}");
    }
}
```

---

## 8. Serde — Serialization

```rust
use serde::{Deserialize, Serialize};
use serde_json;

#[derive(Debug, Serialize, Deserialize)]
struct Config {
    #[serde(rename = "server.port")]
    port: u16,
    host: String,
    features: Vec<String>,
}

let json = r#"{"port": 8080, "host": "localhost", "features": ["a"]}"#;
let config: Config = serde_json::from_str(json).unwrap();

// TOML
let config: Config = toml::from_str(toml_str).unwrap();

// YAML (serde_yaml crate)
let config: Config = serde_yaml::from_str(yaml_str).unwrap();

// Custom serialization
use serde::{Serializer, Deserializer};

fn serialize<S>(date: &Date, s: S) -> Result<S::Ok, S::Error>
where S: Serializer {
    s.serialize_str(&date.to_string())
}
```

---

## 9. Common Crates Reference

| Crate | Purpose |
|-------|---------|
| `tokio` | Async runtime (1.x) |
| `async-trait` | async methods in traits |
| `reqwest` | HTTP client |
| `axum` | Web framework |
| `warp` | Web framework (filter-based) |
| `serde` | Serialization |
| `serde_json`, `toml`, `serde_yaml` | Format support |
| `clap` | CLI argument parsing |
| `anyhow` | Ergonomic errors |
| `thiserror` | Custom error types |
| `tracing` | Structured logging/tracing |
| `tracing-subscriber` | Tracing output |
| `rand` | Random numbers |
| `chrono` | Date/time |
| `regex` | Regular expressions |
| `url` | URL parsing |
| `sqlx` | Async database |
| `uuid` | UUID generation |
| `once_cell` | Lazy static initialization |
| `parking_lot` | Faster mutexes |

---

## 10. Macro Reference

```rust
// declarative macro
macro_rules! my_vec {
    ($($elem:expr),*) => {
        {
            let mut v = Vec::new();
            $(v.push($elem);)*
            v
        }
    };
}

// procedural macro (derive)
use serde::{Serialize, Deserialize};
#[derive(Serialize, Deserialize, Debug)]
struct Point { x: f64, y: f64 }

// Built-in derive macros
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)]
#[derive(Default)]              // for structs with all Default fields
#[derive(Serialize, Deserialize)]

// attribute macros
#[tokio::main]                  // async main()
#[test]                         // test function
#[cfg(feature = "something")]  // conditional compilation
#[allow(dead_code)]            // suppress warnings
```
