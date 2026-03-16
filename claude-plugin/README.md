# inquiry_attrs — Claude Code Plugin

A Claude Code plugin that teaches Claude how to install and use the
[`inquiry_attrs`](https://github.com/pniemczyk/inquiry_attrs) gem in any
Rails, StoreModel, or plain Ruby project.

## What's Included

```
claude-plugin/
├── .claude-plugin/
│   └── plugin.json                          # Plugin metadata
└── skills/
    └── inquiry-attrs/
        ├── SKILL.md                         # Core skill — auto-loaded when relevant
        ├── references/
        │   ├── installation.md              # Step-by-step setup guide
        │   ├── patterns.md                  # Usage patterns and recipes
        │   └── reserved-predicates.md       # Critical gotchas with nil?/blank?/etc.
        └── examples/
            ├── activerecord.rb              # AR model examples
            ├── storemoderl.rb               # StoreModel integration
            ├── plain_ruby.rb                # Plain Ruby class examples
            └── testing.rb                   # Minitest + RSpec test patterns
```

## Installing the Plugin

### Option A — Point Claude Code at the plugin directory

```bash
# One-off session
claude --plugin-dir /path/to/inquiry_attrs/claude-plugin

# Or copy the plugin directory to your project
cp -r /path/to/inquiry_attrs/claude-plugin /your/project/.claude-plugins/inquiry-attrs
```

### Option B — Install globally in `~/.claude`

```bash
mkdir -p ~/.claude/plugins/inquiry-attrs
cp -r /path/to/inquiry_attrs/claude-plugin/* ~/.claude/plugins/inquiry-attrs/
```

## How the Skill Activates

The skill automatically activates when you ask Claude things like:

- "Add inquiry_attrs to this project"
- "Install inquiry_attrs"
- "Add `.active?` / `.admin?` style methods to my model"
- "Replace `user.status == 'active'` with predicates"
- "Make attributes nil-safe with inquiry methods"
- "How do I use the inquirer macro?"
- "What are the reserved predicate names in inquiry_attrs?"

Claude will then know:
1. How to add the gem and run the installer
2. How to call `inquirer` in AR models, StoreModel, and plain Ruby
3. The correct order (`inquirer` must come after `attr_accessor`)
4. The reserved predicate name gotcha (`nil?`, `blank?`, `present?`, `empty?`, `frozen?`)
5. How to write tests for inquired attributes
