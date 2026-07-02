# graftcode

[![Graftcode](https://img.shields.io/badge/Graftcode-Integration--Layer--Free-0A66C2?style=for-the-badge)](https://github.com/grft-dev/graftcode)

[![Roadmap](https://img.shields.io/badge/Roadmap-Featurebase-8A2BE2?style=for-the-badge&logo=roadmap&logoColor=white)](https://graftcode.featurebase.app/dashboard/roadmap)
[![Quick Start](https://img.shields.io/badge/Quick_Start-Guide-00C853?style=for-the-badge&logo=github&logoColor=white)](https://github.com/grft-dev/graftcode-quick-start-guide)
[![Stars](https://img.shields.io/github/stars/grft-dev/graftcode?style=for-the-badge&logo=github&logoColor=white&color=0A66C2)](https://github.com/grft-dev/graftcode/stargazers)

## **Call remote code like local dependencies.**

Graftcode is the integration-layer-free development framework that lets you call methods across any language and runtime as if they were local, without writing integration code, SDKs, or client layers.

**Supported Languages**  
![.NET](https://img.shields.io/badge/.NET-512BD4?logo=dotnet&logoColor=white)
![Java](https://img.shields.io/badge/Java-007396?logo=java&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?logo=nodedotjs&logoColor=white)
![Go](https://img.shields.io/badge/Go-00ADD8?logo=go&logoColor=white)
![PHP](https://img.shields.io/badge/PHP-777BB4?logo=php&logoColor=white)
![C++](https://img.shields.io/badge/C%2B%2B-00599C?logo=c%2B%2B&logoColor=white)
![Ruby](https://img.shields.io/badge/Ruby-CC342D?logo=ruby&logoColor=white)

**Platforms & OS**  
![Windows](https://img.shields.io/badge/Windows-0078D6?logo=windows&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black)
![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white)

**Cloud Ready**  
![Azure](https://img.shields.io/badge/Azure-0089D6?logo=microsoftazure&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-FF9900?logo=amazonaws&logoColor=white)
![GCP](https://img.shields.io/badge/GCP-4285F4?logo=googlecloud&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)



**Call remote code like local dependencies. Let package managers keep them fresh.**

Graftcode is the **integration-free development layer** that lets you call methods across languages and runtimes as native dependencies: no integration layer code, no SDKs, no client code.

Turn your public methods into instantly consumable, strongly-typed clients in any technology using regular package managers.

Access your remote services from web, mobile, and edge clients. Seamlessly connect microservices and expose business logic the way it was always meant to be clean, type-safe, and effortless.

Imagine a world where you can share business logic across any technology as easily as publishing a package to a public repository. With Graftcode, you simply write public methods, communicate errors through exceptions, and call them like local code.

Graftcode eliminates the need for REST, gRPC, Thrift, or coupling your code to message buses and event systems. It reduces your codebase by up to 50%, dramatically improves AI-assisted development (lower token usage, higher efficiency, and simpler code reviews), and makes every backend immediately MCP-compatible for AI agents.

It also enables true modular monoliths you can decompose and recombine modules at will, switch communication channels (WebSocket, HTTP/2, RabbitMQ, Kafka, Service Bus, SQS, Pub/Sub, etc.) without changing a single line of code, and build truly polyglot systems with zero integration overhead.

---

## What is Graftcode?

Instead of building and maintaining APIs, DTOs, clients, and integration layers, Graftcode lets you:

- Write **public methods** in your preferred language
- Run them on **Graftcode Gateway** (multi-runtime host running on your cloud instances, bare metal, containers or local machine)
- Install auto-generated, strongly-typed **Grafts** in any other project via `npm`, `dotnet`, `pip`, etc.
- Call remote code **as if it was local**

**No controllers. No OpenAPI. No client code. No IDL.**

Graftcode works with monoliths, microservices, and everything in between — and comes with built-in MCP support for AI agents.

---

## Quick Start

### 1. Host your service

```bash
# 1. Build/package your library
# 2. Navigate to the output folder
# 3. Download Graftcode Gateway

# Windows
iwr https://grft.dev/get | iex

# Linux / macOS
curl -fsSL https://grft.dev/get | sh

# Run the Gateway with your module:
# Example with .NET
gg --modules ./MyService.dll
```

### 2. Consume it from anywhere
Install a Graft using your package manager (example for npm):
```bash
npm install --registry https://grft.dev/YOUR_PROJECT_ID @graft/your-service-name
```

Graft installed command can be obtained by navigating to your service hosted on Graftcode Gateway i.e. http://localhost if executed locally.

### 3. Call it like local code
Once you install Graft in client project of your choice, just import classes replicating your remote API and call the methods as if they where available as local module.
```typescript
import { EnergyPriceCalculator } from '@graft/...';

const price = await EnergyPriceCalculator.GetPrice();
```

Whenever API evolves, graftcode will take care to inform your package manager that new version of dependency is available.

### Interactive Quick-Start Journey

The best way to get started with Graftcode is our hands-on tutorial series.

**[→ Open Quick Start Guide](https://github.com/grft-dev/graftcode-quick-start-guide)**

It contains step-by-step tutorials such as:
- Connecting frontend to backend
- Exposing your first service
- Switching between monolith and microservices
- Using with AI agents (MCP)

## Core Repositories

| Repository                        | Purpose                                      |
|-----------------------------------|----------------------------------------------|
| [graftcode-gateway](https://github.com/grft-dev/graftcode-gateway) | Core multi-runtime host (the engine)        |
| [graftcode-demos](https://github.com/grft-dev/graftcode-demos)     | Live demos + performance comparisons        |
| [graftcode-quick-start-guide](https://github.com/grft-dev/graftcode-quick-start-guide) | Hands-on tutorials |
| [graftcode-documentation](https://github.com/grft-dev/graftcode-documentation) | Full documentation |
| [graftcode-docker-images](https://github.com/grft-dev/graftcode-docker-images) | Official Docker images |
| [graftcode-plugins](https://github.com/grft-dev/graftcode-plugins) | Official Open Source plugins for any communication channel (ServiceBus, RabbitMQ, Kafka etc..) |

## Key Features

- Cross-language & cross-runtime method calls
- Auto-generated, always-in-sync strongly-typed clients
- Monolith ↔ Microservices switching with zero code changes
- Built-in **MCP** support for AI agents
- Up to 70% faster & significantly lower CPU usage than REST/gRPC
- Works with 20+ languages and 10+ package managers
- 50% reduction in codebase volume
- 30-70% lower cost of tokens for any change lead by AI
- significantly higher success rate of AI-assisted development, leveraging better context efficiency

## Exposing your methods for AI Agents (MCP)

Graftcode has native support for **Model Context Protocol (MCP)**. Any public static methods with value type arguments and results become callable as MCP tools. Run your module on Graftcode Gateway, enter the service address and copy MCP configuration from Graftcode Vision portal exposed by Graftcode Gateway.

### Ready to use AI Agent rules

Adding graftcode rules to your repository allows you to build entire systems using pure prompts — the AI agent reads the rules and can easily build new systems, migrate existing solutions to graftcode, and evolve your system with significantly higher context efficiency and lower token usage.

Use command below in your project root directly to download rules for any IDE Agent.

```bash
# PowerShell
iwr https://grft.dev/get | iex

# Linux / macOS
curl -fsSL https://grft.dev/get | sh

# Alternative with wget
wget -qO- https://grft.dev/get | sh
```

---

## Links

- **Website**: [https://graftcode.com](https://graftcode.com)
- **Portal**: [https://portal.graftcode.com](https://portal.graftcode.com)
- **Academy / Quick Start**: [https://academy.graftcode.com](https://academy.graftcode.com)
- **Docs**: [https://docs.graftcode.com](https://docs.graftcode.com)
- **Discord**: [Join Community](https://discord.gg/2tWb3BAE36)
- **X / Twitter**: [@Graftcode](https://x.com/Graftcode)
- **LinkedIn**: [Graftcode](https://www.linkedin.com/company/graftcode/)
- **Public Roadmap**: [https://graftcode.featurebase.app/dashboard/roadmap](https://graftcode.featurebase.app/dashboard/roadmap)

---

## Used by

Graftcode is already trusted by innovative teams at:

![Total](https://img.shields.io/badge/Total-000000?logo=totalenergies&logoColor=white)
![TRUMPF](https://img.shields.io/badge/TRUMPF-000000?logo=trumpf&logoColor=white)
![Siemens](https://img.shields.io/badge/Siemens-009999?logo=siemens&logoColor=white)
![IQVIA](https://img.shields.io/badge/IQVIA-000000?logo=iqvia&logoColor=white)
![Breas](https://img.shields.io/badge/Breas-000000?logoColor=white)

*(and many more engineering teams building the future of software)*

---

## ⭐ Star us if you like the project

If Graftcode helps you ship faster and cleaner or just inspire you with its bold vision — please star the repository.  
It really helps the project grow and motivates the team.

[![Star](https://img.shields.io/github/stars/grft-dev/graftcode?style=for-the-badge&logo=github&logoColor=white&color=0A66C2)](https://github.com/grft-dev/graftcode/stargazers)

# Contributing
We welcome contributions! Please read our Contributing Guide and feel free to open issues or PRs.

Made with ❤️ for developers who want to focus on business logic instead of integration layers.

## Join the Community

Join other Grafters building the future of software integration.

[![Join Discord](https://img.shields.io/discord/1440810609586339871?style=for-the-badge&logo=discord&logoColor=white&label=Join%20Discord&color=5865F2)](https://discord.gg/2tWb3BAE36)

Chat with the team, get help, share ideas, and stay up to date with the latest developments.
