using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;

namespace PSBuild
{
    public class CommandInfo
    {
        private readonly List<CommandSource> _cmdSources = new List<CommandSource>();
        public string CommandName { get; set; }
        public ReadOnlyCollection<CommandSource> CommandSources { get { return new ReadOnlyCollection<CommandSource>(_cmdSources); } }

        public CommandInfo(string name)
        {
            this.CommandName = name;
        }

        public void AddSource(CommandSource src)
        {
            this._cmdSources.Add(src);
        }

        public bool ContainsSource(string sourceName)
        {
            return this._cmdSources.Any(x => x.Source.Equals(sourceName, StringComparison.OrdinalIgnoreCase));
        }
    }

}
