using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Collections.Generic;
using System.Collections;

namespace pugbg.modules.loghelper
{
    public class LhConfigurationFactory
    {
        public static LhConfiguration Parse(Hashtable dictionary)
        {
            //LHConfiguration ValidationRules
            var validationRules = new Dictionary<string, validationEntry>();
            validationRules.Add("Name", new validationEntry { Mandatory = true, Type = typeof(System.String) });
            validationRules.Add("Default", new validationEntry { Mandatory = false, Type = typeof(System.Boolean), DefaultValue = false });
            validationRules.Add("InitializationScript", new validationEntry { Mandatory = false, Type = typeof(ScriptBlock) });
            validationRules.Add("MessageTypes", new validationEntry { Mandatory = false, Type = typeof(Hashtable) });
            var validation = new Dictionary<string, string>();

            var result = new LhConfiguration();

            foreach (var vr in validationRules.Keys)
            {
                if (dictionary.ContainsKey(vr))
                {
                    if (dictionary[vr].GetType() != validationRules[vr].Type)
                    {
                        validation.Add(vr, $"Configuration Element: '{vr}' should be of type: '{validationRules[vr].Type}'");
                    }
                    else
                    {
                        result.GetType().GetProperty(vr).SetValue(result, dictionary[vr]);
                    }
                }
                else
                {
                    if (validationRules[vr].Mandatory)
                    {
                        validation.Add(vr, $"Missing Configuration Element: '{vr}' of type: '{validationRules[vr].Type}'");
                    }
                    else if (validationRules[vr].DefaultValue != null)
                    {
                        result.GetType().GetProperty(vr).SetValue(result, validationRules[vr].DefaultValue);
                    }
                }
            }

            if (validation.Count > 0)
            {
                throw new Exception(String.Join(", ", validation.Values));
            }

            return result;
        }
    }

    class validationEntry
    {
        public bool Mandatory { get; set; }
        public Type Type { get; set; }
        public object DefaultValue { get; set; }
    }
}
