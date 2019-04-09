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
        //Parameter Path
        [Parameter(Mandatory = true)]
        public String[] Path { get; set; }

        //Parameter Force
        [Parameter(Mandatory = false)]
        public SwitchParameter Force { get; set; }

        //Parameter Scope
        [Parameter(Mandatory = false)]
        public EnvironmentVariableTarget[] Scope { get; set; } = { EnvironmentVariableTarget.Machine };

        protected override void ProcessRecord()
        {
            AddPSModulePathEntry.Execute(path: this.Path.ToList(), force: this.Force.IsPresent, scope: this.Scope.ToList());
        }
    }

    internal class AddPSModulePathEntry
    {
        internal static void Execute(IEnumerable<String> path, bool force, IEnumerable<EnvironmentVariableTarget> scope)
        {
            //Check if Path exists
            if (!force)
            {
                foreach (var p in path)
                {
                    if (!Directory.Exists(p))
                    {
                        throw new DirectoryNotFoundException($"Path {p} does not exists");
                    }
                }
            }

            foreach (var scp in scope)
            {
                //Get Current Entries
                var curEntries = GetPSModulePath.Execute(scope: new List<EnvironmentVariableTarget> { scp });
                var newEntries = path.Union(curEntries).ToList();
                SetPSModulePath.Execute(path: newEntries, force: true, scope: new List<EnvironmentVariableTarget> { scp });
            }
        }
    }
}
