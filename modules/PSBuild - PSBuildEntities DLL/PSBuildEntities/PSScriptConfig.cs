using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSBuild
{
    public class PSScriptConfig
    {
        public List<RequiredModuleSpecs> RequiredModules { get; set; }

        public PSScriptConfig()
        {
            this.RequiredModules = new List<RequiredModuleSpecs>();
        }
    }
}
