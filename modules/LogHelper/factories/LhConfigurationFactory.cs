using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Collections.Generic;

namespace pugbg.modules.loghelper
{
    public class LhConfigurationFactory
    {
        public static LhConfiguration Parse(Dictionary<string, object> dictionary)
        {
            var result = new LhConfiguration();
            var validation = new Dictionary<string, string>();

            if (!dictionary.ContainsKey("Name") || dictionary["Name"].GetType() != typeof(System.String))
            {
                validation.Add("Name", "Missing Configuration Element: 'Name' of type: 'System.String'");
            }
            else
            {
                result.Name = dictionary["Name"].ToString();
            }
            if (!dictionary.ContainsKey("Default") || dictionary["Default"].GetType() != typeof(System.Boolean))
            {
                validation.Add("Name", "Missing Configuration Element: 'Default' of type: 'System.Boolean'");
            }
            else
            {
                result.Default = (bool)dictionary["Name"];
            }
            if (!dictionary.ContainsKey("InitializationScript") || dictionary["InitializationScript"].GetType() != typeof(ScriptBlock))
            {
                validation.Add("Name", "Missing Configuration Element: 'InitializationScript' of type: 'ScriptBlock'");
            }
            else
            {
                result.InitializationScript = (ScriptBlock)dictionary["InitializationScript"];
            }
            if (!dictionary.ContainsKey("MessageTypes") || dictionary["MessageTypes"].GetType() != typeof(Dictionary<string, ScriptBlock>))
            {
                validation.Add("Name", "Missing Configuration Element: 'MessageTypes' of type: 'Dictionary<string, ScriptBlock>'");
            }
            else
            {
                result.MessageTypes = (Dictionary<string, ScriptBlock>)dictionary["MessageTypes"];
            }

            return result;
        }
    }
}
