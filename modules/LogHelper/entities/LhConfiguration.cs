using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Collections.Generic;
using System.Collections;

namespace pugbg.modules.loghelper
{
    public class LhConfiguration
    {
        public string Name { get; set; }
        public bool Default { get; set; }
        public ScriptBlock InitializationScript { get; set; }
        public Hashtable MessageTypes { get; set; }
    }
}
