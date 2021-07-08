using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Management.Automation;
using System.Collections;

namespace PSBuild
{
    public class PSModuleValidation
    {
        private bool moduleDefinitionAstIsUpdated = false;

        public string ModuleName {
            get
            {
                if (this.ModuleInfo != null)
                {
                    return this.ModuleInfo.Name;
                }
                return "N/A";
            }
        }
        public PSModuleInfo ModuleInfo { get; set; }
        public System.Management.Automation.Language.Ast ModuleDefinitionAst { get; private set; }
        public string SourceDirectory
        {
            get
            {
                if (this.ModuleInfo != null)
                {
                    return this.ModuleInfo.ModuleBase;
                }
                return null;
            }
        }
        public string TargetDirectory { get; set; }
        public bool IsModule { get; set; }
        public bool IsVersionValid { get; set; }
        public bool IsNewVersion { get; set; }
        public bool SupportVersonControl { get; set; }
        public bool IsReadyForPackaging { get; set; }
        public bool IsValid { get { return IsModule && IsVersionValid && SupportVersonControl; } }
        public int PreferredProcessingOrder { get; internal set; }
        internal PSModuleValidationCollection ParentCollection { get; set; }
        internal PSModuleValidation[] GetInternalDependencies()
        {
            if (this.ModuleInfo == null) { return new PSModuleValidation[0]; }
            if (this.ModuleInfo.RequiredModules == null || this.ModuleInfo.RequiredModules.Count == 0) { return new PSModuleValidation[0]; }

            var depModuleNames = this.ModuleInfo.RequiredModules.Select(rm => rm.Name).ToArray();
            var depModules = ParentCollection.AllModuleNames.Intersect(depModuleNames, StringComparer.OrdinalIgnoreCase).ToArray();

            var res = new PSModuleValidation[depModules.Length];
            for (int i = 0; i < res.Length; i++)
            {
                res[i] = ParentCollection[depModules[i]];
            }
            return res;
        }
        internal int GetPreferredProcessingOrder()
        {
            var ppOrder = -1;
            foreach (var item in GetInternalDependencies())
            {
                var itemProcOrder = item.GetPreferredProcessingOrder();
                if (itemProcOrder > 999999)
                {
                    // unlikely level of nesting, usually caused by circular dependency
                    return 999999;
                }
                if(itemProcOrder > ppOrder)
                {
                    ppOrder = itemProcOrder;
                }
            }
            return ppOrder + 1;
        }

        public PSModuleValidation()
        {
            this.PreferredProcessingOrder = -1;
        }

        public RequiredModuleSpecs[] GetRequiredModules(RequiredModulesFilterOption filter)
        {
            if (this.ModuleInfo == null) { return new RequiredModuleSpecs[0]; }
            if (this.ModuleInfo.RequiredModules == null || this.ModuleInfo.RequiredModules.Count == 0) { return new RequiredModuleSpecs[0]; }

            var reqModules = this.ModuleInfo.RequiredModules.Select(x => new RequiredModuleSpecs(x, this.TargetDirectory)).ToArray();
            switch (filter)
            {
                case RequiredModulesFilterOption.FindAll:
                    return reqModules;

                case RequiredModulesFilterOption.RemoveExternalDependencies:
                    var extDep = GetExternalModuleDependencyNames();
                    return reqModules.Where(x => !extDep.Contains(x.Name, StringComparer.OrdinalIgnoreCase)).ToArray();

                case RequiredModulesFilterOption.RemoveKnownSolutionItems:
                    var solutionItems = this.ParentCollection.AllModuleNames;
                    return reqModules.Where(x => !solutionItems.Contains(x.Name, StringComparer.OrdinalIgnoreCase)).ToArray();

                case RequiredModulesFilterOption.RemoveExternalDependenciesAndKnownSolutionItems:
                    var extDep2 = GetExternalModuleDependencyNames();
                    var solutionItems2 = this.ParentCollection.AllModuleNames;
                    return reqModules
                        .Where(x => (!solutionItems2.Contains(x.Name, StringComparer.OrdinalIgnoreCase)) && (!extDep2.Contains(x.Name, StringComparer.OrdinalIgnoreCase)))
                        .ToArray();

                case RequiredModulesFilterOption.OnlyKnownSolutionItems:
                    var solutionItems3 = this.ParentCollection.AllModuleNames;
                    return reqModules
                        .Where(x => solutionItems3.Contains(x.Name, StringComparer.OrdinalIgnoreCase))
                        .ToArray();

                default:
                    return reqModules;
            }
        }

        private string[] GetExternalModuleDependencyNames()
        {
            if (this.ModuleInfo == null) { return new string[0]; }
            if (this.ModuleInfo.PrivateData == null) { return new string[0]; }

            Hashtable privateData = this.ModuleInfo.PrivateData as Hashtable;
            if (privateData == null) { return new string[0]; }

            Hashtable psData = privateData["PSData"] as Hashtable;
            if (psData == null) { return new string[0]; }

            var emd = psData["ExternalModuleDependencies"];
            if (emd == null) { return new string[0]; }

            return LanguagePrimitives.ConvertTo<string[]>(emd);
        }

        public PSModuleInfo[] GetExternalModuleDependencies()
        {
            var moduleNames = GetExternalModuleDependencyNames();
            if (moduleNames == null || moduleNames.Length == 0) { return new PSModuleInfo[0]; }

            return this.ModuleInfo.RequiredModules
                .Where(x1 => moduleNames.Contains(x1.Name, StringComparer.OrdinalIgnoreCase))
                .ToArray();
        }

        public void Update(PSModuleValidation item)
        {
            if(!this.ModuleName.Equals(item.ModuleName, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("The reference item contains information about another module.");
            }

            this.ModuleInfo = item.ModuleInfo;
            this.IsModule = item.IsModule;
            this.IsVersionValid = item.IsVersionValid;
            this.IsNewVersion = item.IsNewVersion;
            this.SupportVersonControl = item.SupportVersonControl;
            this.IsReadyForPackaging = item.IsReadyForPackaging;
        }
        public void UpdateModuleDefinitionAst(string scriptblock)
        {
            var sb = ScriptBlock.Create(scriptblock);
            this.ModuleDefinitionAst = sb.Ast;
            moduleDefinitionAstIsUpdated = true;
        }
        public string[] GetLocalFunctions()
        {
            if(!moduleDefinitionAstIsUpdated)
            {
                throw new InvalidOperationException("You must call UpdateModuleDefinitionAst first.");
            }
            if (this.ModuleDefinitionAst == null)
            {
                return new string[0];
            }

            return this.ModuleDefinitionAst.FindAll(x => x.GetType().Name == "FunctionDefinitionAst", true).Select(o => ((System.Management.Automation.Language.FunctionDefinitionAst)o).Name ).ToArray();
        }
        public string[] GetNonLocalCommands()
        {
            if (!moduleDefinitionAstIsUpdated)
            {
                throw new InvalidOperationException("You must call UpdateModuleDefinitionAst first.");
            }
            if (this.ModuleDefinitionAst == null)
            {
                return new string[0];
            }

            var localFunctions = GetLocalFunctions();

            return this.ModuleDefinitionAst
                .FindAll(x1 => x1.GetType().Name == "CommandAst", true)
                .Select(x2 => ((System.Management.Automation.Language.CommandAst)x2).GetCommandName())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Except(localFunctions, StringComparer.OrdinalIgnoreCase)
                .Where(x3 => !String.IsNullOrWhiteSpace(x3))
                .ToArray();
        }
        public override string ToString()
        {
            if(this.ModuleInfo != null)
            {
                return $"{this.ModuleInfo.Name}/{this.ModuleInfo.Version}";
            }
            return base.ToString();
        }
    }

    public enum RequiredModulesFilterOption
    {
        FindAll = 0,
        RemoveExternalDependencies = 1,
        RemoveKnownSolutionItems = 2,
        RemoveExternalDependenciesAndKnownSolutionItems = 3,
        OnlyKnownSolutionItems = 4,
    }
}
