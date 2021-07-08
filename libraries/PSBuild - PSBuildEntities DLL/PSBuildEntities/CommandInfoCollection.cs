using System.Collections.ObjectModel;
using System;
using System.Linq;
using Newtonsoft.Json;

namespace PSBuild
{
    public class CommandInfoCollection : KeyedCollection<string, CommandInfo>
    {
        public CommandInfoCollection() : base(StringComparer.OrdinalIgnoreCase)
        {

        }

        protected override string GetKeyForItem(CommandInfo item)
        {
            return item.CommandName;
        }

        public string ToJson()
        {
            return JsonConvert.SerializeObject(this);
        }

        public static CommandInfoCollection FromJson(string input)
        {
            return JsonConvert.DeserializeObject<CommandInfoCollection>(input);
        }
        
        public bool ContainsCommand(string commandName)
        {
            if(String.IsNullOrEmpty(commandName)) { return false; }

            if(commandName.IndexOf("\\") > -1)
            {
                var keyTokens = commandName.Split(new string[] { "\\" }, StringSplitOptions.RemoveEmptyEntries);
                if(keyTokens.Length != 2) { throw new InvalidOperationException($"Unknown command format: {commandName}"); }

                if(!Contains(keyTokens[1]))
                {
                    return false;
                }

                foreach(var src in this[keyTokens[1]].CommandSources)
                {
                    if(src.Source.Equals(keyTokens[0], StringComparison.OrdinalIgnoreCase))
                    {
                        return true;
                    }
                }

                return false;
            }
            else
            {
                return Contains(commandName);
            }
        }

        public ReadOnlyCollection<CommandSource> GetCommandSources(string commandName)
        {
            if (String.IsNullOrEmpty(commandName)) { return new ReadOnlyCollection<CommandSource>(new CommandSource[0]); }

            if (commandName.IndexOf("\\") > -1)
            {
                var keyTokens = commandName.Split(new string[] { "\\" }, StringSplitOptions.RemoveEmptyEntries);
                if (keyTokens.Length != 2) { throw new InvalidOperationException($"Unknown command format: {commandName}"); }

                if (!Contains(keyTokens[1]))
                {
                    return new ReadOnlyCollection<CommandSource>(new CommandSource[0]);
                }

                return new ReadOnlyCollection<CommandSource>(this[keyTokens[1]].CommandSources.Where(src => src.Source.Equals(keyTokens[0], StringComparison.OrdinalIgnoreCase)).ToList());
            }
            else if (Contains(commandName))
            {
                return this[commandName].CommandSources;
            }
            else
            {
                return new ReadOnlyCollection<CommandSource>(new CommandSource[0]);
            }
        }

        public bool TryAdd(CommandInfo item)
        {
            if (!this.Contains(item.CommandName))
            {
                this.Add(item);
                return true;
            }
            else
            {
                return false;
            }
        }

        public bool AddCommandSource(CommandSource item, bool allowDuplicateSources = false)
        {
            if (!this.Contains(item.CommandName))
            {
                var cmdInfo = new CommandInfo(item.CommandName);
                cmdInfo.AddSource(item);
                this.Add(cmdInfo);
                return true;
            }
            else if(allowDuplicateSources || !this[item.CommandName].ContainsSource(item.Source))
            {
                this[item.CommandName].AddSource(item);
                return true;
            }
            else
            {
                return false;
            }
        }

    }

}
