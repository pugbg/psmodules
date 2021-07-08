using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSBuild
{
    public class CommandSource
    {
        public string CommandName { get; set; }
        public string CommandType { get; set; }
        public string Source { get; set; }
        public CommandSourceLocation SourceLocation { get; set; }

        public string GetCommandFQDN()
        {
            return string.Format("{0}{1}", (string.IsNullOrEmpty(Source) ? "" : $"{Source}\\"), CommandName);
        }

        public CommandSource(string commandName, string type, string source, CommandSourceLocation srcLocation)
        {
            SourceLocation = CommandSourceLocation.Unknown;
        }

        public CommandSource(System.Management.Automation.CommandInfo command, CommandSourceLocation srcLocation)
        {
            CommandName = command.Name;
            CommandType = command.CommandType.ToString();
            Source = command.Source;

            SourceLocation = srcLocation;
        }

        public override string ToString()
        {
            return $"{Source} ({SourceLocation})";
        }
    }
}
