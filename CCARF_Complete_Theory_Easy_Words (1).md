# CCAR-F Complete Study Notes

## Claude Certified Architect -- Foundations

**Easy-language theory, architecture examples, decision rules, and
revision notes**

> Prepared for a developer with intermediate Claude knowledge and one
> hour of study per day. This is an independent study companion, not an
> official Anthropic publication and not a copy of the exam question
> bank. Use the latest official exam guide before booking because exam
> objectives and product features can change.

------------------------------------------------------------------------

## Table of contents

1.  Exam overview and how to study
2.  The big picture: Claude application architecture
3.  Domain 1 --- Agentic Architecture & Orchestration (27%)
4.  Domain 2 --- Tool Design & MCP Integration (18%)
5.  Domain 3 --- Claude Code Configuration & Workflows (20%)
6.  Domain 4 --- Prompt Engineering & Structured Output (20%)
7.  Domain 5 --- Context Management & Reliability (15%)
8.  Cross-domain architecture decisions
9.  Scenario-solving method
10. Quick revision cheat sheet
11. Practice questions
12. Official learning resources

------------------------------------------------------------------------

# 1. Exam overview

The Anthropic exam page currently describes CCAR-F as a 60-question,
120-minute exam. Questions can be multiple-choice or multiple-response
and are based on realistic architecture scenarios. The reported passing
score is 720 on a scaled 100--1000 scale. The five domain weights are:

  Domain                                     Weight   Approximate share of 60 questions
  ---------------------------------------- -------- -----------------------------------
  Agentic Architecture & Orchestration          27%                                  16
  Tool Design & MCP Integration                 18%                                  11
  Claude Code Configuration & Workflows         20%                                  12
  Prompt Engineering & Structured Output        20%                                  12
  Context Management & Reliability              15%                                   9

The approximate question counts are only a study-planning aid; actual
exam forms and scaled scoring may differ.

### What the exam is really testing

It is not simply asking whether you know Claude terminology. It tests
whether you can choose a sensible design when given constraints such as:

-   The task is predictable or uncertain.
-   The workflow must be fast, cheap, safe, or auditable.
-   The model needs to use external systems.
-   Some steps can run in parallel.
-   An action can change customer data or spend money.
-   The context is too large for one request.
-   The output must follow a strict schema.
-   The system must recover from tool failures.

### Suggested four-week plan

Study for 60 minutes daily:

-   10 minutes: recall yesterday's notes without looking.
-   25 minutes: study one concept.
-   15 minutes: draw or explain an architecture.
-   10 minutes: answer scenario questions and review mistakes.

  Week   Main focus
  ------ -----------------------------------------------------------------
  1      Agent loops, orchestration, subagents, safety and handoffs
  2      Tool design, tool calling and MCP
  3      Claude Code configuration, permissions, hooks and workflows
  4      Prompts, structured output, context, reliability and mock tests

------------------------------------------------------------------------

# 2. The big picture: a Claude application

A production Claude solution is usually more than a model call. Think of
it as a small software system:

``` text
User / Application
       |
       v
Your backend (Java / Python / Node)
       |
       +---- instructions and conversation context
       |
       v
Claude model
       |
       +---- normal answer
       |
       +---- request to use a tool
                    |
                    v
             Tool execution layer
                    |
          +---------+----------+
          |         |          |
        Database   API       File system
          |         |          |
          +---------+----------+
                    |
                    v
              Tool result
                    |
                    v
              Claude model
                    |
                    v
              Final response
```

### Responsibilities

**Claude model** - Understands the request. - Reasons about the
available information. - Chooses whether a tool is needed. - Produces a
response or a tool-use request.

**Your application** - Sends messages and tool definitions to Claude. -
Executes approved tool calls. - Checks permissions and validates
arguments. - Returns tool results to Claude. - Handles retries,
timeouts, logs and business rules.

**Tools and external systems** - Perform real actions: read a database,
search a system, create a ticket, calculate a value, or update a record.

**MCP** - Provides a standard way for an AI application to discover and
use capabilities exposed by external MCP servers.

**Claude Code** - An agentic coding tool that can inspect and modify a
software project using configured tools, permissions and instructions.

**Claude Agent SDK** - Lets developers build applications around the
agent loop and tool-use capabilities, rather than implementing every
loop detail themselves.

### Important distinction

Claude does not magically execute your Java method. Claude can request a
tool call. Your program or an authorised tool runtime executes it, then
sends the result back.

------------------------------------------------------------------------

# 3. Domain 1 --- Agentic Architecture & Orchestration (27%)

This is the largest exam domain.

## 3.1 Workflow versus agent

### Traditional workflow

A workflow follows steps that the developer has already decided.

Example: monthly invoice processing:

1.  Read invoice.
2.  Validate required fields.
3.  Check the vendor.
4.  Save the invoice.
5.  Send a confirmation.

The path is mostly known in advance.

### Agent

An agent is given a goal and can decide what action to take next based
on what it observes.

Example: investigate a failed payment:

1.  Inspect the payment record.
2.  Decide which service log to query.
3.  Read the result.
4.  Decide whether to inspect a retry record.
5.  Summarise the likely cause or ask a human for help.

### How to choose

  Situation                            Usually prefer
  ------------------------------------ -----------------------------------
  Fixed steps and predictable rules    Traditional workflow
  Steps depend on what is discovered   Agent
  Exact calculations and validations   Normal code
  Natural-language interpretation      Model
  High-risk action                     Deterministic checks and approval
  Small task with one model response   Single-shot model call

**Exam principle:** Do not introduce an autonomous agent when a simple
deterministic workflow solves the problem.

## 3.2 The agentic loop

An agent commonly works in a repeated cycle:

1.  Receive the goal and context.
2.  Ask the model what to do next.
3.  If the model requests a tool, validate and execute it.
4.  Return the tool result to the model.
5.  Let the model decide the next step.
6.  Stop when the task is complete, a limit is reached, or human input
    is required.

``` text
             +----------------------+
             | Goal + current state |
             +----------+-----------+
                        |
                        v
                 +-------------+
                 | Call Claude |
                 +------+------+
                        |
             +----------+-----------+
             |                      |
             v                      v
       Final response          Tool request
             |                      |
             v                      v
            Stop             Validate request
                                    |
                                    v
                              Execute tool
                                    |
                                    v
                              Tool result
                                    |
                                    +------> back to Claude
```

The model's response may indicate that it is finished or that it wants
to use a tool. In the Claude API, the response stop reason is important:
a `tool_use` stop reason means the application should process the
requested tool call; an end-of-turn stop reason indicates the model has
finished its turn. Follow the current API documentation for exact
response fields and SDK behaviour.

### Why the loop matters

A tool result may change the plan. For example, if a search returns no
records, the next action may be a different search. A fixed sequence
might continue with an invalid assumption.

## 3.3 Single-agent architecture

One agent handles the task and has access to a set of tools.

Example: an IT support agent can: - Search the knowledge base. - Check
ticket status. - Read service health. - Draft a response.

**Advantages** - Simple to build and debug. - Less coordination
overhead. - Easier to keep one shared context. - Often cheaper and
faster than multiple agents.

**Disadvantages** - One agent may receive too many unrelated
instructions. - A complex task can become difficult to manage. - A large
tool list can make tool selection harder.

Use one agent when the work is reasonably coherent and does not need
separate specialist contexts.

## 3.4 Multi-agent architecture

Multiple agents handle separate parts of a task. A coordinator may
divide the work and combine results.

Real-life analogy: a project manager assigns research to one specialist,
security review to another, and testing to a third.

Example: analyse a software release: - Research agent: inspect
requirements. - Code agent: inspect implementation. - Test agent:
inspect test coverage. - Coordinator: combine findings.

**Advantages** - Separates responsibilities. - Independent work may run
in parallel. - Specialist instructions can be smaller and clearer. - One
subtask's context need not pollute another's context.

**Disadvantages** - More model calls and cost. - More latency and
coordination. - Handoffs can lose important details. - Agents may
produce conflicting conclusions. - Debugging is harder.

**Exam principle:** Use multiple agents only when the work has genuinely
separable responsibilities, independent investigations, or context
boundaries that justify the overhead.

## 3.5 Coordinator and subagent pattern

The coordinator: - Understands the overall goal. - Breaks the goal into
tasks. - Assigns tasks to subagents. - Defines what each subagent should
return. - Combines and checks the results. - Decides whether another
step is required.

A subagent: - Receives a focused task. - Works within its own allowed
tools and context. - Returns a result to the coordinator. - Should not
silently expand its responsibility.

Good handoff example:

``` text
Task: Review the authentication module for security issues.
Scope: Inspect only authentication-related code.
Do not modify files.
Return:
1. Finding
2. Evidence (file and line)
3. Severity
4. Recommended fix
```

Poor handoff: "Look at the project and tell me everything."

A good handoff includes task, scope, constraints, expected output and
completion condition.

## 3.6 Parallel versus sequential execution

**Parallel:** independent tasks can run at the same time.

Example: - Agent A checks API logs. - Agent B checks database errors. -
Agent C checks recent deployments.

These tasks do not depend on each other's results.

**Sequential:** a later task needs an earlier result.

Example: 1. Discover the customer ID. 2. Fetch that customer's orders.
3. Analyse the orders. 4. Draft a response.

Do not run step 2 before step 1 has produced the required ID.

**Rule:** Parallelise independent work; sequence dependent work.

## 3.7 Task decomposition

Break a large task into smaller pieces that have: - Clear boundaries. -
A useful output. - Limited scope. - Explicit dependencies. - A
completion condition.

Example: "Prepare a release report" can become: 1. Collect merged pull
requests. 2. Collect deployment records. 3. Identify known incidents. 4.
Summarise changes. 5. Review the report for missing evidence.

Avoid splitting a task into many tiny pieces. Coordination overhead can
become greater than the work itself.

## 3.8 Context isolation and handoffs

A subagent may work with a separate context. This reduces irrelevant
information and helps it focus.

But isolated context means it may not know everything the coordinator
knows. Pass the facts it needs explicitly.

A good handoff contains: - Objective. - Relevant facts. - Files or
systems in scope. - Constraints. - Previous findings, if relevant. -
Expected response format.

Do not pass the entire conversation if a short, precise summary is
enough.

## 3.9 Claude Agent SDK concepts

The Claude Agent SDK provides building blocks for agentic applications.
The exact API evolves, so learn the concepts and verify current SDK
names in official documentation.

Important concepts include:

-   **Agent loop:** repeated model/tool interaction until completion or
    a stopping condition.
-   **Tools:** capabilities the agent can request.
-   **Permissions:** rules controlling what the agent may do.
-   **Subagents / Task delegation:** focused work delegated to another
    agent.
-   **Hooks:** points where application logic can run during a lifecycle
    event.
-   **Session management:** maintaining, resuming or branching work.
-   **Allowed tools:** limiting which capabilities are available in a
    particular context.

### Task and tool restrictions

A delegated task should receive only the tools it needs. A read-only
review agent should not receive file-writing or deployment permissions.

### Forking and resuming sessions

-   **Resume:** continue an existing session when its context and
    history are still useful.
-   **Fork:** create a branch from an existing session when a different
    line of investigation is needed.
-   **Fresh session:** start without stale context when the old
    discussion is irrelevant or confusing.

Do not carry old assumptions into a new task just because the previous
session exists.

## 3.10 Guardrails and safety

An agent should not be trusted with unlimited authority.

Use multiple layers:

1.  **Tool allowlist:** only expose necessary tools.
2.  **Input validation:** validate arguments and identifiers.
3.  **Application authorization:** check the actual user's access.
4.  **Business rules:** enforce limits in normal code.
5.  **Human approval:** require confirmation for sensitive actions.
6.  **Audit log:** record who requested what and what happened.
7.  **Execution limits:** cap tool calls, time, cost and recursion.
8.  **Output validation:** verify the result before acting on it.

A prompt saying "never delete a customer" is not a reliable security
boundary. Enforce the rule in the application and tool permissions.

## 3.11 Human-in-the-loop

Human review is appropriate when: - An action is irreversible. - Money
or legal commitments are involved. - A customer account could be changed
or closed. - Confidence is low and consequences are high. - Policy
requires human authorisation.

A useful pattern:

``` text
Agent prepares action
       |
       v
Application validates it
       |
       v
Human reviews details
       |
   Approve / Reject
       |
       v
Application executes only if approved
```

The approval must be tied to the specific action and its parameters. Do
not let a general approval authorise unrelated future actions.

## 3.12 Hooks and deterministic controls

A hook is a configured point in a tool or agent lifecycle where code can
inspect, modify, allow, block or respond to an event, depending on the
hook type.

Examples: - Block a dangerous shell command. - Format a file after
editing. - Log a tool invocation. - Check a policy before a tool runs. -
Normalise an input or output.

**Prompt versus hook:**

-   Prompt: asks the model to behave in a certain way. It influences
    behaviour but is not a hard guarantee.
-   Hook or application check: runs deterministic code at a defined
    lifecycle point. It can enforce a rule if correctly configured.

Use prompts for guidance. Use code, permissions and hooks for rules that
must be enforced.

## 3.13 Error recovery and resilience

Common failures: - Tool timeout. - Invalid tool arguments. - API rate
limit. - External service unavailable. - Permission denied. - Model
response does not match expected format.

A robust agent should: 1. Detect the failure. 2. Classify it. 3. Retry
only when appropriate. 4. Use backoff for temporary failures. 5. Avoid
repeating non-idempotent actions blindly. 6. Escalate when recovery is
unsafe or impossible. 7. Preserve enough context to explain what
happened.

**Idempotency:** repeating the same operation should not create an
unintended duplicate effect. For example, a payment request should use
an idempotency key where supported.

------------------------------------------------------------------------

# 4. Domain 2 --- Tool Design & MCP Integration (18%)

## 4.1 What is a tool?

A tool is a capability that an application exposes to Claude.

Examples: - `get_order(order_id)` - `search_customer(email)` -
`create_support_ticket(title, description)` -
`calculate_tax(amount, country)`

The model decides whether a tool is useful and may request it. Your
application executes the tool.

### Tool-use lifecycle

1.  Your application sends the user request, context and tool
    definitions.
2.  Claude responds with a tool-use request.
3.  Your application checks the requested tool and arguments.
4.  The application executes the tool.
5.  The application sends a tool-result message.
6.  Claude uses the result and continues or finishes.

The model's tool request is not proof that the operation succeeded. Only
the actual tool result can establish that.

## 4.2 Good tool design

A good tool has: - One clear responsibility. - A descriptive name. - A
useful description. - Explicit input fields. - Correct data types. -
Required and optional fields identified. - Constraints and allowed
values. - Predictable output. - Structured errors.

Bad tool: `do_task(data)`

Better tools: - `find_invoice(invoice_number)` -
`get_invoice_status(invoice_id)` -
`submit_invoice_for_approval(invoice_id)`

Prefer a small number of clear, task-oriented tools over a giant generic
tool.

## 4.3 Tool descriptions matter

Claude uses tool names, descriptions and schemas to decide which tool to
use.

Weak description: "Updates a record."

Better description: "Updates the delivery address for an existing order.
Requires an order ID and a validated address. Does not change billing
information."

Explain: - What the tool does. - When it should be used. - When it
should not be used. - Important limitations. - Whether it changes data.

## 4.4 Schema design

A schema tells the model what arguments are valid.

Example:

``` json
{
  "name": "get_order",
  "description": "Fetch one order using its unique ID.",
  "input_schema": {
    "type": "object",
    "properties": {
      "order_id": {
        "type": "string",
        "description": "Unique order identifier"
      }
    },
    "required": ["order_id"],
    "additionalProperties": false
  }
}
```

Important schema concepts: - `type`: expected data type. - `properties`:
allowed object fields. - `required`: mandatory fields. - `enum`: allowed
values. - `description`: explains meaning. - `additionalProperties`:
controls unexpected fields, when supported by the schema mode.

Validate arguments in your application too. A schema is not a substitute
for authorisation or business validation.

## 4.5 Read tools versus write tools

**Read tool:** retrieves information. Example: get invoice status.

**Write tool:** changes something. Example: approve an invoice.

Write tools deserve stronger controls: - Check user identity and
permission. - Validate business rules. - Confirm important actions. -
Use idempotency where appropriate. - Log the change. - Return a clear
result.

A tool's name or description does not grant permission.

## 4.6 Tool errors

Return useful, structured errors instead of vague messages.

Example:

``` json
{
  "error": {
    "code": "ORDER_NOT_FOUND",
    "message": "No order exists for the supplied ID.",
    "retryable": false
  }
}
```

A useful error tells the agent: - What failed. - Whether it may retry. -
What information is missing. - Whether the user or a human must
intervene.

Do not expose secrets, stack traces or internal security details to the
model or end user.

## 4.7 Tool selection and routing

When many tools exist: - Use clear names and descriptions. - Group tools
by business capability. - Limit the tools available to a specialised
agent. - Avoid overlapping tools with confusing responsibilities. - Use
deterministic routing when the choice is a fixed business rule.

If two tools do nearly the same thing, the model may choose
inconsistently. Improve the descriptions or simplify the tool set.

## 4.8 What is MCP?

MCP stands for **Model Context Protocol**.

It is an open protocol that standardises how AI applications connect to
external tools and context providers.

Real-life analogy: USB standardises how devices connect to computers.
MCP standardises how an AI host connects to external capabilities.

Without a shared protocol, each AI application may need a custom
integration for every external service. MCP provides common conventions.

## 4.9 MCP architecture

``` text
+--------------------------+
| Host application         |
| (Claude desktop / agent) |
+------------+-------------+
             |
             v
+--------------------------+
| MCP Client               |
| Manages protocol session |
+------------+-------------+
             |
       MCP connection
             |
             v
+--------------------------+
| MCP Server               |
| Exposes capabilities     |
+------------+-------------+
             |
       +-----+------+
       |            |
       v            v
    Database    External API
```

**Host:** the application where the AI experience lives.

**Client:** the component in the host that communicates with an MCP
server.

**Server:** exposes capabilities such as tools, resources and prompts.

One host can connect to multiple MCP servers. Each server can expose
different capabilities.

## 4.10 MCP primitives

The three important server-side primitives are:

### Tools

Actions the model can request.

Examples: - Search a ticket. - Create an issue. - Query a database.

### Resources

Data or context that can be read.

Examples: - A project document. - A database record. - A file or
configuration.

### Prompts

Reusable prompt templates that a server can offer.

Examples: - "Summarise this repository." - "Review this pull request."

Remember: - Tool = do something. - Resource = read or provide context. -
Prompt = reusable instruction template.

## 4.11 MCP transport and lifecycle

MCP defines protocol messages and lifecycle behaviour. Common transport
options include: - **stdio:** client launches or communicates with a
local server through standard input/output. - **Streamable HTTP:**
communication with a remote server over HTTP, with streaming support
where applicable.

At a high level: 1. Client establishes a connection. 2. Client and
server initialise and negotiate capabilities. 3. Client discovers
available capabilities. 4. Client invokes tools or reads resources as
supported. 5. Connection is managed and eventually closed.

Do not assume every server supports every capability. Discover and
respect the capabilities it advertises.

## 4.12 MCP security

Treat MCP servers as external integrations that require security review.

Important controls: - Use trusted servers. - Give minimum required
permissions. - Protect credentials. - Validate tool inputs. - Apply
user-level authorisation. - Restrict network access where possible. -
Review what data is sent to a server. - Watch for prompt injection in
external content. - Log sensitive actions. - Require approval for risky
operations.

A server being available through MCP does not mean every user should be
allowed to invoke every tool.

## 4.13 MCP versus custom API integration

  -----------------------------------------------------------------------
  Need                                Suitable choice
  ----------------------------------- -----------------------------------
  One application needs one private   Direct API integration may be
  API                                 simplest

  Several MCP-capable clients need    MCP server is useful
  the same tools                      

  Existing service has a stable REST  Keep the API; expose it through MCP
  API                                 if needed

  Only a simple internal function is  A direct tool may be enough
  needed                              

  Need reusable standardised context  Consider MCP
  and tools                           
  -----------------------------------------------------------------------

MCP does not replace REST, databases or business services. It
standardises the AI-facing integration layer.

------------------------------------------------------------------------

# 5. Domain 3 --- Claude Code Configuration & Workflows (20%)

## 5.1 What is Claude Code?

Claude Code is an agentic coding tool. It can inspect a repository,
understand code, edit files and use configured tools to support software
development.

It is not merely autocomplete. It can work through multi-step coding
tasks, but its actions must remain within configured permissions and
review practices.

Common uses: - Explain an unfamiliar codebase. - Find a bug. - Implement
a feature. - Generate tests. - Review a pull request. - Refactor code. -
Run approved commands.

## 5.2 Configuration and settings

Claude Code has configuration and settings that control behaviour,
permissions, tools and project conventions.

Understand the difference between: - User-level preferences. -
Project-level configuration. - Local/private settings. - Managed
organisational settings.

Exact file names, precedence and supported keys can change. Use the
current Claude Code settings documentation when implementing a
configuration.

A useful principle: shared project instructions should live with the
project; personal preferences should not accidentally become team-wide
rules.

## 5.3 CLAUDE.md

`CLAUDE.md` contains instructions that Claude Code should consider when
working in a project or directory.

Think of it as an onboarding guide for an AI developer.

Useful content: - Project overview. - Architecture and module
boundaries. - Build and test commands. - Coding conventions. - Important
files. - Testing requirements. - Security constraints. - Things the
agent should avoid.

Example:

``` markdown
# Project instructions

## Technology
- Java 21
- Spring Boot
- Maven
- PostgreSQL

## Build and test
- Run: ./mvnw test
- Run one test class before the full suite.

## Coding rules
- Keep controllers thin.
- Put business logic in services.
- Validate external input.
- Do not log passwords or tokens.

## Before finishing
- Summarise changed files.
- Report tests run and their results.
- Do not claim tests passed unless they were executed.
```

### Good CLAUDE.md practices

-   Keep instructions concise and actionable.
-   Put stable project knowledge there.
-   Avoid duplicating huge documentation.
-   Avoid contradictory rules.
-   Link to detailed documents where appropriate.
-   Keep instructions relevant to the directory or project.

A very large instruction file consumes context and can make important
rules harder to notice.

## 5.4 Instruction hierarchy and scope

Claude Code can load instructions from different locations and scopes.
The exact precedence is product-specific.

Understand these ideas: - Organisational instructions may set mandatory
constraints. - Project instructions describe shared repository
practices. - Directory-specific rules can apply to a particular part of
a project. - User preferences can customise personal workflow.

Do not assume a lower-level instruction can override a higher-priority
managed policy. Check the current documentation for exact precedence.

## 5.5 Skills

A skill is reusable guidance and/or a workflow for a type of task.

Examples: - Review a pull request using the team's checklist. - Generate
a Spring Boot controller following house style. - Prepare a release
note. - Analyse a production log.

Think of a skill as a reusable playbook.

A good skill explains: - When it applies. - What inputs it expects. -
What steps to follow. - What output to produce. - What constraints to
respect.

Use skills for repeatable specialised work. Do not put every possible
instruction into one giant skill.

## 5.6 Custom commands and slash commands

Commands provide a convenient way to invoke a repeatable workflow.

Example conceptual command: `/review-pr`

It may instruct Claude Code to: 1. Inspect the diff. 2. Check
correctness. 3. Look for security issues. 4. Review test coverage. 5.
Return findings with file references.

Commands are useful when a person wants to deliberately start a known
workflow.

Product versions may evolve the relationship between commands and
skills. Learn the current documented format rather than relying on old
syntax.

## 5.7 Hooks

Hooks let you run code at defined points in a Claude Code lifecycle.

Examples: - Before a tool runs, inspect the command. - After a file
edit, run a formatter. - When a session starts, load required context. -
Before completion, run a validation step.

Use hooks for deterministic actions. A prompt that says "always format
files" is weaker than an enforced formatting hook.

Hooks must be configured carefully. A broken hook can block work or
create unwanted side effects.

## 5.8 Permissions and security

Claude Code permissions control what actions or tools are allowed,
denied or require approval, according to the current configuration.

Good practices: - Start with least privilege. - Allow only required
tools. - Restrict destructive commands. - Require approval for risky
operations. - Do not put secrets in prompts or project instructions. -
Review generated code and shell commands. - Keep production credentials
and deployment authority tightly controlled.

Do not use broad permission bypasses simply to make an agent more
convenient.

## 5.9 Plan mode

Plan mode is useful when a task is large or risky.

Instead of immediately changing files, Claude first explores and
proposes a plan.

A sensible sequence: 1. Understand the task. 2. Inspect relevant files.
3. Identify dependencies. 4. Propose implementation steps. 5. Ask for
clarification or approval if needed. 6. Implement. 7. Run tests and
report results.

Use plan-first behaviour for broad refactoring, architectural changes
and multi-file work. A tiny typo fix may not need a lengthy plan.

## 5.10 Sessions and checkpoints

A session preserves the conversation and task context.

Use: - Existing session when continuing the same task. - Resume when
previous context is useful. - Fork when exploring a different direction
from a known starting point. - Fresh session when old context is stale
or irrelevant.

Checkpoints help recover from mistakes or compare changes. They do not
replace Git commits, backups or code review.

## 5.11 Claude Code in CI/CD

Claude Code can support automated development workflows such as: - Code
review. - Test generation. - Change summaries. - Documentation checks. -
Issue triage.

A safe CI design: 1. Trigger on a pull request. 2. Provide only the
required repository context. 3. Give read-only access for review tasks.
4. Ask for findings with evidence. 5. Validate generated output. 6. Keep
merge and deployment decisions under normal controls.

Do not give an automated reviewer unrestricted production access.

------------------------------------------------------------------------

# 6. Domain 4 --- Prompt Engineering & Structured Output (20%)

## 6.1 What is prompt engineering?

Prompt engineering is the practice of designing instructions and context
so the model can perform a task accurately and consistently.

A useful prompt explains: - Role or perspective. - Task. - Input data. -
Constraints. - Decision criteria. - Output format. - What to do when
information is missing.

Weak prompt: "Analyse this invoice."

Better prompt: "Extract invoice number, vendor, invoice date, currency
and total amount. Do not guess missing values. Return JSON matching the
supplied schema. Include a list of fields that could not be read."

## 6.2 System instructions versus user request

**System/developer-level instructions:** define the application's
behaviour, policies and constraints.

**User message:** describes what the user wants for this particular
interaction.

Keep stable application rules separate from task-specific data.

Do not rely on the user to repeat critical safety rules in every
request.

## 6.3 Explicit criteria

Give the model measurable criteria.

Weak: "Find good candidates."

Better: "Select records with status ACTIVE, a score above 80, and a
valid email address. Return at most 10 records. Do not include records
that fail any condition."

Explicit criteria reduce ambiguity.

## 6.4 Few-shot prompting

Few-shot prompting means giving examples of desired input and output.

Example:

``` text
Input: "The package arrived two days late."
Output: {"sentiment":"negative","topic":"delivery"}

Input: "The product works exactly as expected."
Output: {"sentiment":"positive","topic":"product_quality"}

Now classify:
"The support team never replied."
```

Examples help show the desired pattern, especially when labels or
formatting are unusual.

Good examples should: - Be correct. - Cover different cases. - Be
representative. - Use consistent output formats. - Avoid unnecessary
length.

More examples are not automatically better. They consume context and can
introduce conflicting patterns.

## 6.5 Prompt chaining

Prompt chaining splits a large task into smaller model steps.

Example: process a contract.

1.  Extract parties and dates.
2.  Identify obligations.
3.  Identify unusual clauses.
4.  Summarise risks.

Each step has a defined input and output.

Benefits: - Easier to inspect intermediate results. - Smaller focused
prompts. - Easier to retry a failed stage. - Different steps can use
different validation.

Costs: - More calls. - More latency and cost. - Errors can pass from one
stage to another.

Use chaining when the task naturally has stages or intermediate
validation is valuable. Do not chain simple tasks unnecessarily.

## 6.6 Structured output

Normal text is flexible but difficult for software to consume reliably.

Example normal text: "The invoice total appears to be 5,000 rupees."

Structured JSON:

``` json
{
  "invoice_total": 5000,
  "currency": "INR",
  "confidence": "medium"
}
```

A schema defines the expected structure.

Example JSON Schema:

``` json
{
  "type": "object",
  "properties": {
    "invoice_total": {
      "type": ["number", "null"]
    },
    "currency": {
      "type": ["string", "null"]
    },
    "confidence": {
      "type": "string",
      "enum": ["low", "medium", "high"]
    }
  },
  "required": [
    "invoice_total",
    "currency",
    "confidence"
  ],
  "additionalProperties": false
}
```

Exact supported schema features depend on the API's structured-output
mode. Check the current API documentation.

## 6.7 Tool use versus structured output

These solve different problems.

-   **Tool use:** asks the application to perform an action or retrieve
    information.
-   **Structured output:** asks the model to return data in a defined
    format.

Example: - Need to look up an order? Use a tool. - Need the final result
as JSON? Use structured output.

Do not confuse a JSON-looking answer with a real tool execution.

## 6.8 Validation and retry

Never assume that a model-produced value is valid just because it looks
correct.

A robust pipeline:

``` text
Model output
    |
    v
Parse JSON
    |
    v
Validate schema
    |
    +---- valid ----> business validation ----> use result
    |
    +---- invalid --> provide error details --> retry or escalate
```

Validate: - Syntax. - Required fields. - Types. - Allowed values. -
Business constraints. - Cross-field consistency.

Use bounded retries. If the model repeatedly fails, stop and report the
issue rather than looping forever.

## 6.9 Prompt optimisation

Improve prompts systematically: 1. Define what success means. 2. Collect
representative inputs. 3. Create a baseline prompt. 4. Evaluate results.
5. Identify failure patterns. 6. Change one important factor at a time.
7. Compare against the baseline. 8. Keep the change only if it improves
results without harming other cases.

Do not judge prompt quality using one successful example.

## 6.10 Prompt caching

Prompt caching can reduce repeated processing cost and latency for
supported repeated prompt prefixes.

Imagine sending a large company policy document with every question. If
the same prefix is reused, caching can avoid reprocessing that stable
content in the normal way.

Good candidates: - Long stable system instructions. - Reused reference
documents. - Common tool definitions. - Shared context across many
requests.

Less suitable: - Content that changes on every request. - Very short
prompts where caching overhead provides little benefit.

Cache behaviour, minimum token thresholds, cache duration and pricing
are model/API-specific. Verify current Anthropic documentation.

Keep stable content together and variable content later where the API's
caching rules support that layout. Do not assume cached content remains
current after the source document changes.

## 6.11 Batch processing

For large independent workloads, batch processing may be more
appropriate than sending one synchronous request per record.

Example: classify 100,000 support messages.

Consider: - Throughput. - Latency tolerance. - Cost. - Retry strategy. -
Partial failures. - Result tracking. - Rate limits.

Use synchronous calls for interactive responses. Consider batch
facilities for large offline jobs when supported.

------------------------------------------------------------------------

# 7. Domain 5 --- Context Management & Reliability (15%)

## 7.1 What is context?

Context is the information available to the model for its current work.

It may include: - System instructions. - Developer instructions. -
Conversation messages. - Tool definitions. - Tool results. - Retrieved
documents. - Relevant summaries.

The context window is the model's finite capacity for input and
generated output.

Real-life analogy: working memory on a desk. If you place too many
papers on the desk, important information becomes difficult to manage.

## 7.2 Context-window management

Problems with excessive context: - Increased cost and latency. -
Important details become harder to find. - Old or irrelevant information
distracts from the task. - The application may exceed the model's
context limit.

Good practices: 1. Send relevant information, not everything. 2.
Retrieve documents only when needed. 3. Summarise completed work. 4.
Keep stable instructions concise. 5. Remove duplicated content. 6.
Preserve critical constraints. 7. Split independent work into focused
tasks.

## 7.3 Retrieval and summarisation

For a large knowledge base, do not put every document into every prompt.

A retrieval pattern: 1. Convert documents into searchable units. 2. Find
the relevant passages for the current question. 3. Send the best
evidence to Claude. 4. Ask for an answer grounded in that evidence. 5.
Preserve source references.

Summaries are useful, but they can omit details. Keep original records
available when exact evidence is needed.

## 7.4 Context compaction

Compaction means reducing a long conversation or task history into a
shorter representation so work can continue.

A good summary preserves: - Goal. - Decisions already made. - Important
facts. - Constraints. - Current status. - Unresolved questions. - Next
steps. - Relevant file or record identifiers.

Example:

``` text
Goal: Fix invoice reconciliation defect.
Completed: Found incorrect currency conversion in InvoiceService.
Decision: Preserve existing API contract.
Constraints: Do not change database schema.
Tests: Two unit tests currently fail.
Next: Correct conversion and add regression test.
```

Do not preserve every conversational detail. Preserve what is needed to
continue correctly.

## 7.5 Context isolation

Different subtasks may need different context.

Example: - Security reviewer needs security requirements and relevant
source files. - Test writer needs behaviour and test conventions. -
Documentation writer needs the public API and intended behaviour.

Providing each worker with all unrelated context wastes tokens and
increases confusion.

## 7.6 Provenance and evidence

Provenance means knowing where a fact came from.

For important claims, preserve: - Source document. - File name or record
ID. - Page or line when available. - Retrieval timestamp. - Whether the
content is directly observed or inferred.

This is especially important for financial, legal, customer and
operational workflows.

Do not let a model invent a citation or claim that it checked a source
when it did not.

## 7.7 Rate limits and quotas

APIs may restrict: - Requests per minute. - Input tokens per minute. -
Output tokens per minute. - Concurrent requests. - Model-specific usage.

When a rate limit occurs: 1. Detect the rate-limit response. 2. Wait
according to the retry guidance. 3. Use exponential backoff with jitter
where appropriate. 4. Limit concurrency. 5. Queue work if necessary. 6.
Avoid retry storms.

A rate limit is not necessarily a permanent failure.

## 7.8 Timeouts and retries

Use timeouts so requests cannot hang indefinitely.

Retry only when: - The failure is temporary. - Repeating the operation
is safe. - The retry budget is not exhausted.

Do not blindly retry: - Invalid arguments. - Permission denied. -
Business-rule rejection. - Non-idempotent writes without protection.

Use exponential backoff for transient failures:

``` text
Attempt 1 -> wait 1 second
Attempt 2 -> wait 2 seconds
Attempt 3 -> wait 4 seconds
Then stop or escalate
```

The actual delay and maximum attempts should be selected for the service
and its latency requirements.

## 7.9 Observability

Observability means being able to understand what happened inside the
system.

Useful signals: - Request ID and session ID. - Model and API version. -
Latency. - Input/output token usage. - Tool requested. - Tool execution
time. - Retry count. - Error category. - Final status. - Human approval
outcome.

Avoid logging secrets, private customer content or unnecessary personal
data.

## 7.10 Reliability patterns

**Timeout:** stop waiting after a defined duration.

**Retry:** try again after a temporary failure.

**Backoff:** increase the wait between retries.

**Circuit breaker:** temporarily stop calling a failing service to
prevent cascading failures.

**Fallback:** use a safe alternative when the primary path is
unavailable.

**Idempotency:** prevent duplicate effects from repeated requests.

**Dead-letter queue:** retain messages that repeatedly fail so they can
be inspected and handled.

**Human escalation:** send work to a person when automated recovery is
unsafe or unsuccessful.

## 7.11 Cost and latency

Cost and latency can increase with: - More model calls. - Longer
context. - Larger outputs. - Multiple agents. - Repeated tool calls. -
Unbounded retries.

Ways to improve: - Use a smaller/simple workflow where possible. -
Reduce irrelevant context. - Parallelise independent tasks when
beneficial. - Cache stable repeated content when supported. - Set
tool-call and token budgets. - Use batch processing for suitable offline
tasks. - Avoid repeated work by preserving useful results.

Do not optimise cost by removing essential validation or safety checks.

------------------------------------------------------------------------

# 8. Cross-domain architecture decisions

These comparisons are especially useful in scenario questions.

## 8.1 Agent versus workflow

Choose a workflow when steps are fixed. Choose an agent when decisions
depend on observations and the next action cannot be fully predefined.

## 8.2 Single agent versus multi-agent

Choose a single agent by default. Add subagents when responsibilities
are genuinely separable, parallel work is valuable, or separate context
is useful.

## 8.3 Prompt versus code enforcement

Use a prompt to guide model behaviour. Use application code, permissions
or hooks when a rule must be enforced reliably.

## 8.4 Direct API versus MCP

Use direct integration when it is the simplest fit for one application.
Use MCP when standardised discovery and reuse across MCP-capable clients
are valuable.

## 8.5 Tool versus resource

A tool performs an action. A resource provides data or context.

## 8.6 Tool use versus JSON output

Tool use interacts with the outside world. Structured output shapes the
model's response.

## 8.7 Retry versus escalate

Retry temporary failures safely. Escalate permanent, ambiguous or
high-risk failures.

## 8.8 Resume versus fork versus fresh session

Resume the same task. Fork to explore a different direction. Start fresh
when previous context is stale or misleading.

## 8.9 Human approval versus autonomous execution

Allow low-risk, reversible actions within clear permissions. Require
approval for high-impact or irreversible actions.

------------------------------------------------------------------------

# 9. Scenario-solving method

The exam uses realistic situations. Read the scenario and identify the
real constraint before choosing a technology.

Use this checklist:

1.  **Goal:** What outcome is required?
2.  **Predictability:** Are steps fixed or dynamic?
3.  **Dependencies:** Which tasks depend on previous results?
4.  **Separation:** Are tasks independent enough for subagents?
5.  **Integration:** Does the model need a tool, resource or external
    service?
6.  **Safety:** What could go wrong if the action is incorrect?
7.  **Context:** What information is essential?
8.  **Output:** Does the application require a schema?
9.  **Failure:** What happens on timeout, invalid output or rate limit?
10. **Cost:** Is the design unnecessarily complex?

### Common wrong-answer patterns

Be careful with answers that: - Add multiple agents without a reason. -
Give every agent every tool. - Use prompts as the only security
control. - Retry a non-idempotent action blindly. - Put an entire
knowledge base in every prompt. - Trust unvalidated model output. - Give
write or production access to a read-only reviewer. - Use MCP when a
simple direct integration is sufficient. - Parallelise tasks that have
dependencies. - Continue forever without a stop condition.

### A useful decision example

**Scenario:** A support agent must look up an order, determine whether
it is eligible for a refund, and issue a refund.

A sensible design: 1. Use a read tool to fetch the order. 2. Use
deterministic business code to calculate refund eligibility. 3. Present
the proposed refund amount. 4. Obtain required customer or human
approval. 5. Use a protected refund tool. 6. Use idempotency to prevent
duplicate refunds. 7. Record the result and return a clear status.

Why not let the model decide everything? Because eligibility, money
movement and duplicate prevention are business-critical rules.

------------------------------------------------------------------------

# 10. Quick revision cheat sheet

  -----------------------------------------------------------------------
  Term                                Easy meaning
  ----------------------------------- -----------------------------------
  Agent                               Model-driven system that chooses
                                      actions toward a goal

  Workflow                            Predefined sequence of steps

  Agentic loop                        Model → tool → result → model cycle

  Coordinator                         Agent that manages and combines
                                      delegated work

  Subagent                            Focused agent working on a smaller
                                      task

  Handoff                             Passing task, context and expected
                                      result to another worker

  Parallelism                         Running independent tasks at the
                                      same time

  Hook                                Code triggered at a defined
                                      lifecycle point

  Guardrail                           Control that limits unsafe or
                                      invalid behaviour

  Human-in-the-loop                   Person reviews or approves an
                                      action

  Tool                                Capability the model can request

  Tool schema                         Definition of valid tool arguments

  MCP                                 Standard protocol for connecting AI
                                      applications to external
                                      capabilities

  MCP host                            Application containing the AI
                                      experience

  MCP client                          Component communicating with an MCP
                                      server

  MCP server                          Program exposing tools, resources
                                      or prompts

  MCP tool                            Action exposed by an MCP server

  MCP resource                        Data/context exposed by an MCP
                                      server

  MCP prompt                          Reusable prompt template exposed by
                                      a server

  CLAUDE.md                           Project or directory instructions
                                      for Claude Code

  Skill                               Reusable specialised
                                      instructions/workflow

  Plan mode                           Plan before making changes

  Structured output                   Model response constrained to a
                                      defined schema

  Few-shot                            Prompting with examples

  Prompt chaining                     Breaking a task into multiple model
                                      steps

  Prompt caching                      Reusing eligible repeated prompt
                                      content

  Context window                      Model's finite working input/output
                                      capacity

  Compaction                          Compressing old context into a
                                      useful summary

  Provenance                          Evidence showing where information
                                      came from

  Idempotency                         Repeating an operation does not
                                      create duplicate effects

  Backoff                             Waiting longer between retries

  Circuit breaker                     Temporarily stopping calls to a
                                      failing service

  Observability                       Ability to understand system
                                      behaviour from logs and metrics
  -----------------------------------------------------------------------

### Ten rules to remember

1.  Prefer the simplest architecture that meets the requirement.
2.  Use workflows for fixed steps and agents for dynamic decisions.
3.  Use subagents only when their separation provides value.
4.  Parallelise independent tasks; sequence dependent tasks.
5.  Keep tools focused, descriptive and narrowly permissioned.
6.  Use hooks and application code for deterministic enforcement.
7.  Validate model output before using it.
8.  Keep context relevant and preserve critical facts during compaction.
9.  Retry transient failures safely; escalate when recovery is unsafe.
10. Require human approval for sensitive actions.

------------------------------------------------------------------------

# 11. Practice questions

These are original study questions, not official exam questions.

## Q1. Fixed process

A system must validate a tax form using ten fixed checks. The checks
never change. What is the best starting architecture?

A. Multi-agent system\
B. Deterministic workflow\
C. Autonomous agent with unrestricted tools\
D. Coordinator with five subagents

**Answer: B.** Fixed and predictable steps are usually better handled by
normal code and workflows.

## Q2. Independent investigations

Three independent teams must inspect logs, database health and recent
deployments. Their findings are combined into one report. Which pattern
may help?

A. Sequential execution only\
B. Parallel subagents with a coordinator\
C. One unrestricted agent that changes production\
D. A single prompt with no tools

**Answer: B.** The investigations are independent and can be delegated,
provided coordination overhead is justified.

## Q3. Critical security rule

An agent must never delete a production customer. What is the strongest
design?

A. Add "never delete" to the prompt only\
B. Ask the model to be careful\
C. Deny deletion through permissions and application-side enforcement\
D. Add more examples to the prompt

**Answer: C.** Critical rules require deterministic enforcement, not
just instructions.

## Q4. MCP primitive

An MCP server exposes a searchable project document for the model to
read. Which primitive best describes this?

A. Resource\
B. Hook\
C. Coordinator\
D. Session fork

**Answer: A.** A resource provides data or context.

## Q5. MCP tool

An MCP server exposes an operation to create a support ticket. Which
primitive is this?

A. Prompt\
B. Resource\
C. Tool\
D. Context window

**Answer: C.** A tool performs an action.

## Q6. Tool schema

Claude repeatedly supplies an invalid status value. What should you
improve?

A. Remove all descriptions\
B. Define allowed values in the schema and validate in application code\
C. Give the tool more permissions\
D. Increase the context window

**Answer: B.** Explicit allowed values and server-side validation reduce
invalid requests.

## Q7. Claude Code project knowledge

Where should stable repository-specific build and coding instructions
generally live?

A. In every user message\
B. In a suitable project instruction file such as CLAUDE.md\
C. In production logs\
D. In a database password file

**Answer: B.** Project instructions make shared conventions available to
Claude Code.

## Q8. Repeatable coding process

A team repeatedly asks Claude Code to review pull requests using the
same checklist. What is useful?

A. A reusable skill or command workflow\
B. A larger context window only\
C. A new MCP server for every pull request\
D. Unrestricted shell access

**Answer: A.** Reusable workflows make repeated specialised tasks
consistent.

## Q9. Strict JSON

A downstream Java service requires a valid JSON object. What should you
do?

A. Ask for JSON and trust it without checking\
B. Use a supported structured-output/schema mechanism and validate the
result\
C. Ask Claude to avoid punctuation\
D. Convert any text into JSON by removing spaces

**Answer: B.** Schema constraints plus application validation are safer.

## Q10. Large context

An agent receives thousands of pages even though only three pages are
relevant. What is a better approach?

A. Always send every page\
B. Retrieve relevant passages and preserve source references\
C. Remove all system instructions\
D. Add more agents without changing context

**Answer: B.** Retrieval reduces irrelevant context and helps ground the
response.

## Q11. Temporary rate limit

A request receives a temporary rate-limit response. What is generally
appropriate?

A. Retry immediately in a tight loop\
B. Use bounded retry with backoff and respect retry guidance\
C. Disable all validation\
D. Create more concurrent requests

**Answer: B.** Backoff reduces pressure and avoids retry storms.

## Q12. Refund safety

A refund operation may be requested twice because of a network timeout.
What helps prevent duplicate refunds?

A. A longer prompt\
B. Idempotency key and server-side checks\
C. More subagents\
D. A larger output token limit

**Answer: B.** Idempotency protects the external side effect from
duplicate execution.

------------------------------------------------------------------------

# 12. Official learning resources

Start with these resources and use the latest documentation for
implementation details.

1.  **CCAR-F certification and exam guide**\
    https://anthropic-partners.skilljar.com/claude-certified-architect-foundations-certification

2.  **Anthropic Academy**\
    https://anthropic.skilljar.com/

3.  **Claude API documentation**\
    https://docs.anthropic.com/

4.  **Tool use documentation**\
    https://docs.anthropic.com/en/docs/build-with-claude/tool-use/overview

5.  **Model Context Protocol**\
    https://modelcontextprotocol.io/

6.  **Claude Code documentation**\
    https://docs.anthropic.com/en/docs/claude-code/overview

7.  **Claude Agent SDK documentation**\
    https://docs.anthropic.com/en/docs/claude-code/sdk

8.  **Anthropic prompt engineering**\
    https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview

------------------------------------------------------------------------

# Final preparation advice

For an architect-level exam, memorising product names is not enough.
Practise explaining *why* one architecture is safer, simpler, cheaper or
more reliable than another.

For every scenario, ask:

-   Can normal code solve this more reliably?
-   Does the model really need to decide the next step?
-   Is delegation worth the overhead?
-   What is the minimum permission required?
-   What happens when a tool fails?
-   How will I validate the output?
-   What context is essential?
-   When must a human approve the action?

If you can answer these questions consistently, you will be developing
the architectural judgement the CCAR-F exam is designed to assess.

**Important:** This guide is a learning companion. It does not guarantee
a passing score. The official exam guide and current Anthropic
documentation take precedence if details differ.
