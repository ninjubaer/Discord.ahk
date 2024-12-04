# Discord.ahk
_An easy-to-use discord bot library for AutoHotkey v2.0+_
*****

### Installation:
Download the library from the [Github Repository](https://github.com/ninjubaer/discord.ahk)\
Download AutoHotkey v2 from [the official website](https://autohotkey.com/download/ahk-v2.exe)

*****

#### Getting Started
To get started, include the library by using the `#include` directive before the code is being used.
```ahk
#include <DISCORD>
```
*****
## Objects
- **Discord.Bot** is the bot itself.
- **Discord.REST** is for any REST api traffic. Is included in a `Discord.Bot` instance.
- **Discord\.DM** is used to create a Direct Message to a user.
- **Discord.User** is a user Object.
- **Discord.Message** is a message that you can send/edit/delete
- **Discord.Embed** is the Discord Embed Builder
- **Discord.TimeStamp** creates a Discord Timestamp.
- **Discord.Command** is used to create commands
    - **Discord.Command.SUB_COMMAND** create subcommands
    - **Discord.Command.SUB_COMMAND_GROUP** (not yet implemented)
- **Discord.Event** creates an event that can be used with the (Discord.Bot).on and (Discord.Bot).once methods
- **Discord.Intents** has a list of intents that are passed to the `Discord.Bot` constructor method
- **Discord.Presence** is a list of discord presences that a bot can have
- **Discord.Attachment** is used to create a file attachment with the two subclasses:
    - **Discord.Attachment.File**
    - **Discord.Attachment.Bitmap**
- **Discord.Component** has following subclasses:
    - **Discord.Component.TypeEnum** a list of component types
    - **Discord.Component.ButtonStyles** a list of button styles
    - **Discord.Component.TextStyles** a list of text styles
    - **Discord.Component.ActionRow** used to create an action row
    - **Discord.Component.Button** is used to create a button object which can be added to a `Discord.Component.ActionRow`
    - **Discord.Component.TextInput** can be added to a `Discord.Component.ActionRow` in a modal.
    - **Discord.Component.StringSelectMenu** a drop down list for string.
    - **Discord.Component.UserSelectMenu** a drop down list for members
    - **Discord.Component.MentionableSelectMenu** a drop down list for all mentionables (roles and users)
    - **Discord.Component.RoleSelectMenu** a drop down list for roles
    - **Discord.Component.ChannelSelectMenu** a drop down list for channels in the guild.
- **Discord.Interaction** used for an interaction handler with the `INTERACTION_CREATE` event.
- **Discord.Modal** is used to create a Modal.
***

