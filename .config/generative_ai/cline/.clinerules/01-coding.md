# What is important for coding

## Common things
- When encountering modules or packages with unclear specifications, use the MCP tool to search and investigate their specifications.
- When adding new functions or methods, write them after the final line of similar function groups within the file.
- Create functions and methods in small units whenever possible.
- Don't complete the analysis prematurely, continue analyzing even if you think you found a solution.
- Keep each file's line count under 1000 lines. Before adding test code, count the number of lines in the file you're planning to add to using the shell command: "awk 'END { print NR }' ". Then, determine whether that number exceeds 1000 using the MCP tool. If it's less than 1000, append to the existing test file. If it's more than 1000, create a new file in the same directory and append to that file.

## Test Driven Development (TDD)
- When implementing features requested by users, always implement test code for those features as well.
- After implementing features requested by users, confirm with the user before implementing the test code for those features.
- When implementing test code, keep the Red-Green-Refactor cycle in mind.
- Test methods are implemented based on the Arrange-Act-Assert pattern.
- Once the implemented test code passes normally, check the coverage and report it to the user. Then, improve the coverage.

## SOLID principles
Be mindful of SOLID principles. SOLID acronym stands for five design principles that help make software more maintainable and scalable:
- Single Responsibility Principle
- Open/Closed Principle
- Liskov Substitution Principle
- Interface Segregation Principle
- Dependency Inversion Principle

## Python
- When creating functions, basically make them as instance methods of a class. When creating test functions, also create a test class and make them as instance methods.
- When testing modules, execute with `python -m pytest --cov=src --cov-branch --tb=short -vv`.

### Naming Conventions

Use PascalCase for the following:
- Classes
- Exceptions
- Test classes

Use lower_snake_case for the following:
- Directory names
- File names
- Modules
- Methods
- Functions
- Variables

Begin the words `test_` to use lower_snake_case for the following:
- Test methods
- Test functions

Use UPPER_SNAKE_CASE for the following:
- Environment variables
- Constants
- Global configurations


Components
Type definitions
Interfaces


Use kebab-case for the following:

Directory names (e.g., components/auth-wizard)
File names (e.g., user-profile.tsx)


Use camelCase for the following:

Variables
Functions
Methods
Hooks
Properties
Props


Use uppercase for the following:

Environment variables
Constants
Global configurations


For boolean variables, use a verb as prefix: isLoading, hasError, canSubmit

## Go

### Points to keep in mind during development
- When creating functions, basically make them as methods of a struct. When creating test functions, it's fine to make them as standalone functions.
- When creating test functions, include the name of the struct after the prefix 'Test'. And, add the suffix '_Normal' for test case names that test the normal path.
- When testing modules, execute with `go test -coverprofile=coverage.out ./...`.
- Once the implemented test code passes normally, check the coverage and report it to the user. Then, to improve coverage, run the `go tool cover -html=coverage.out -o coverage.html` command. From the results, add test cases to cover the parts of the functionality you were implementing that aren't covered by tests yet.
w- Always make struct field names start with capital letters

### Naming Conventions
Use PascalCase for the following:
- Public structs
- Public interfaces
- Public methods
- Public functions
- Public variables
- Public constants
- Public fields
- Any identifier that needs to be accessible outside the package

Use camelCase for the following:
- Private methods
- Private functions
- Private variables
- Private constants
- Private fields
- Local variables

Use short names for the following:
- Loop counters (i, j, k, etc.)
- Temporary variables (with short scope)
- Method receivers (typically 1-2 characters)
- Error variables (err)

Use lowercase for the following:
- Package names (a single lowercase word, or kebab-case if it doesn't fit)
- Directory names (a single lowercase word, or kebab-case if it doesn't fit)
- File names (lowercase with underscores)

Special cases:
- Acronyms (URL, HTTP): all uppercase when public, all lowercase when private
- Interfaces: single method interfaces are named with the method name + "er"
- Test files: named as filename + "_test.go"

### How to TDD with mock
1. Code processes with interface for the following process: HTTP request, OS file, runtime calling and etc...
e.g. `util.go` for HTTP request:
```go
package github

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

// HTTPClient インターフェースを定義
type HTTPClient interface {
	Do(req *http.Request) (*http.Response, error)
}

// GitHubClient 構造体を修正（テスト用）
type GitHubClient struct {
	httpClient HTTPClient
	token      string
}

// NewGitHubClient は新しいGitHubクライアントを作成します
func NewGitHubClient(token string) *GitHubClient {
	return &GitHubClient{
		httpClient: &http.Client{},
		token:      token,
	}
}

// doRequest はHTTPリクエストを実行し、レスポンスを処理します（テスト用に簡略化）
func (c *GitHubClient) doRequest(method, url string, body io.Reader) ([]byte, error) {
	req, err := http.NewRequest(method, url, body)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Accept", "application/vnd.github.v3+json")
	if c.token != "" {
		req.Header.Set("Authorization", "token "+c.token)
	}
	if method == "POST" || method == "PATCH" || method == "PUT" {
		req.Header.Set("Content-Type", "application/json")
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode >= 400 {
		var ghError GitHubError
		if err := json.Unmarshal(respBody, &ghError); err != nil {
			return nil, fmt.Errorf("HTTP error: %d - %s", resp.StatusCode, string(respBody))
		}
		ghError.StatusCode = resp.StatusCode
		return nil, &ghError
	}

	return respBody, nil
}
```

2. Definite struct and method for mock.
e.g. `util_test.go`:
```go
package github

import (
  "net/http"
)

// 'MockHTTPClient' struct is a mock for HTTP client.
type MockHTTPClient struct {
	DoFunc func(req *http.Request) (*http.Response, error)
}

// 'Do' method executes HTTP request.
func (m *MockHTTPClient) Do(req *http.Request) (*http.Response, error) {
	return m.DoFunc(req)
}
```
