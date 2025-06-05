# Smart-Water-Bottle Backend 
## Technology Overview
- [FastEndpoints](https://fast-endpoints.com/)
- [Supabase](https://supabase.com/)

## Architecture

Built with **Vertical Slice Architecture** using [FastEndpoints](https://fast-endpoints.com/). 
Features are organized as independent slices containing all necessary components (endpoints, models, logic) rather than traditional layered architecture.

# Installation and Usage
### Using Docker
- Have [Docker](https://www.docker.com/) set up
- Get the source code, e.g. with...
```sh
git clone https://github.com/kvnlnk/swpm-smart-water-bottle.git
cd backend/smart-water-bottle-backend
```
- Run `docker compose up`
### Using local setup
- Have [.Net 8](https://dotnet.microsoft.com/en-us/) set up
- Make a copy of `.env.example` and name it `.env` (will be Git-ignored)
- Set the names and values of your secret environment variables in there
- Run the application:
```sh
dotnet build
dotnet run
```

# Development

### Conventions
- Comments start with a space and a capital letter, e.g. `// This is a comment`
- Identifiers of properties are usually PascalCase, e.g. `MyProperty`
- Identifiers of dependency-injected properties are camelCase with a leading underscore, e.g. `_myProperty`