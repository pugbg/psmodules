using System;
using System.Management.Automation;
using System.Linq;
using System.Collections.Generic;
using System.IO;

namespace pugbg.modules.loghelper
{
    [Cmdlet("Add", "PSModulePathEntry")]
    [OutputType(typeof(void))]
    public class AddPSModulePathEntryCmdlet : Cmdlet
    {
        #region Parameters

        //Parameter Path
        [Parameter(Mandatory = true)]
        public String[] Path { get; set; }

        //Parameter Force
        [Parameter(Mandatory = false)]
        public SwitchParameter Force { get; set; }

        //Parameter Scope
        [Parameter(Mandatory = false)]
        public EnvironmentVariableTarget[] Scope { get; set; } = { EnvironmentVariableTarget.Machine };

        #endregion

        #region Execution

        protected override void ProcessRecord()
        {
            //Check if Path exists
            if (!Force.IsPresent)
            {
                foreach (var p in Path)
                {
                    if (!Directory.Exists(p))
                    {
                        throw new DirectoryNotFoundException($"Path {p} does not exists");
                    }
                }
            }

            foreach (var scp in Scope)
            {
                //Get Current Entries
                var curEntries = new GetPSModulePathCmdlet() { Scope = new[] { scp } }.Invoke<string>().Where(x => !String.IsNullOrEmpty(x));
                var newEntries = Path.Union(curEntries).ToArray();
                WriteVerbose(String.Join(",", newEntries));
                var cmd = new SetPSModulePathCmdlet() { Path = newEntries, Scope = new[] { scp }, Force = true };
                cmd.Invoke();
            }
        }
    }

    #endregion
}
