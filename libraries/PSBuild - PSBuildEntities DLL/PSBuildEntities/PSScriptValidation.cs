using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using System.Management.Automation;
using System.Collections;

namespace PSBuild
{
    public class PSScriptValidation
    {
        private bool scriptDefinitionAstIsUpdated = false;

        public PSScriptInfo ScriptInfo { get; set; }
        public PSScriptConfig ScriptConfig { get; set; }

        public string Name
        {
            get
            {
                if (this.ScriptInfo != null)
                {
                    return this.ScriptInfo.Name;
                }
                return null;
            }
        }
        public string SourceDirectory
        {
            get
            {
                if (this.ScriptInfo != null)
                {
                    return this.ScriptInfo.ScriptBase;
                }
                return null;
            }
        }
        public string ScriptPath
        {
            get
            {
                if (this.ScriptInfo != null)
                {
                    return this.ScriptInfo.Path;
                }
                return null;
            }
        }
        public string TargetDirectory { get; set; }
        public string RequiredModulesTargetDirectory { get; set; }
        public System.Management.Automation.Language.Ast ScriptDefinitionAst { get; private set; }


        public bool IsScript { get; set; }
        public bool IsVersionValid { get; set; }
        public bool IsNewVersion { get; set; }
        public bool SupportVersonControl { get; set; }
        public bool IsReadyForPackaging { get; set; }
        public string[] ValidationErrors { get; set; }
        public bool IsValid { get { return IsScript && IsVersionValid && SupportVersonControl; } }

        internal PSScriptValidationCollection ParentCollection { get; set; }


        public PSScriptValidation()
        {
            this.ScriptConfig = new PSScriptConfig();
            ValidationErrors = new string[0];
        }

        public PSScriptValidation(Hashtable definition)
        {
            foreach (var dk in definition.Keys)
            {
                if ("ScriptInfo".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    var psobj = LanguagePrimitives.ConvertTo<PSObject>(definition[dk]);
                    var scrInfo = new PSScriptInfo(new Hashtable() {
                        { "Name", psobj.Properties["Name"].Value},
                        { "Version", psobj.Properties["Version"].Value},
                        { "Guid", psobj.Properties["Guid"].Value},
                        { "Path", psobj.Properties["Path"].Value},
                        { "ScriptBase", psobj.Properties["ScriptBase"].Value},
                        { "Description", psobj.Properties["Description"].Value},
                        { "Author", psobj.Properties["Author"].Value},
                        { "CompanyName", psobj.Properties["CompanyName"].Value},
                        { "ExternalModuleDependencies", psobj.Properties["ExternalModuleDependencies"].Value},
                        { "PrivateData", psobj.Properties["PrivateData"].Value},
                        { "RequiredModules", psobj.Properties["RequiredModules"].Value},
                    });

                    this.ScriptInfo = scrInfo;
                }
                else if ("ScriptConfig".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    if (definition[dk] != null)
                    {
                        try
                        {
                            var json = JsonConvert.SerializeObject(definition[dk]);
                            this.ScriptConfig = JsonConvert.DeserializeObject<PSScriptConfig>(json);
                        }
                        catch (Exception ex)
                        {
                            throw new ArgumentException($"Failed to process property ScriptConfig. {ex.Message}");
                        }
                    }
                }
                else if ("TargetDirectory".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    TargetDirectory = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                }
                else if ("RequiredModulesTargetDirectory".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    RequiredModulesTargetDirectory = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                }
                else if ("IsScript".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    IsScript = LanguagePrimitives.ConvertTo<bool>(definition[dk]);
                }
                else if ("IsVersionValid".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    IsVersionValid = LanguagePrimitives.ConvertTo<bool>(definition[dk]);
                }
                else if ("IsNewVersion".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    IsNewVersion = LanguagePrimitives.ConvertTo<bool>(definition[dk]);
                }
                else if ("SupportVersonControl".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    SupportVersonControl = LanguagePrimitives.ConvertTo<bool>(definition[dk]);
                }
                else if ("IsReadyForPackaging".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    IsReadyForPackaging = LanguagePrimitives.ConvertTo<bool>(definition[dk]);
                }
                else if ("ValidationErrors".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    ValidationErrors = LanguagePrimitives.ConvertTo<string[]>(definition[dk]);
                }
            }
        }

        public void Update(PSScriptValidation item)
        {
            if (!this.Name.Equals(item.Name, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("The reference item contains information about another script.");
            }

            this.ScriptInfo = item.ScriptInfo;
            this.ScriptConfig = item.ScriptConfig;
            this.IsScript = item.IsScript;
            this.IsVersionValid = item.IsVersionValid;
            this.IsNewVersion = item.IsNewVersion;
            this.SupportVersonControl = item.SupportVersonControl;
            this.IsReadyForPackaging = item.IsReadyForPackaging;
        }

        public void UpdateScriptDefinitionAst(string scriptblock)
        {
            var sb = ScriptBlock.Create(scriptblock);
            this.ScriptDefinitionAst = sb.Ast;
            scriptDefinitionAstIsUpdated = true;
        }

        public string[] GetLocalFunctions()
        {
            if (!scriptDefinitionAstIsUpdated)
            {
                throw new InvalidOperationException("You must call UpdateScriptDefinitionAst first.");
            }
            if (this.ScriptDefinitionAst == null)
            {
                return new string[0];
            }

            return this.ScriptDefinitionAst.FindAll(x => x.GetType().Name == "FunctionDefinitionAst", true).Select(o => ((System.Management.Automation.Language.FunctionDefinitionAst)o).Name).ToArray();
        }
        public string[] GetNonLocalCommands()
        {
            if (!scriptDefinitionAstIsUpdated)
            {
                throw new InvalidOperationException("You must call UpdateScriptDefinitionAst first.");
            }
            if (this.ScriptDefinitionAst == null)
            {
                return new string[0];
            }

            var localFunctions = GetLocalFunctions();

            return this.ScriptDefinitionAst
                .FindAll(x1 => x1.GetType().Name == "CommandAst", true)
                .Select(x2 => ((System.Management.Automation.Language.CommandAst)x2).GetCommandName())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Except(localFunctions, StringComparer.OrdinalIgnoreCase)
                .Where(x3 => !String.IsNullOrWhiteSpace(x3))
                .ToArray();
        }
        public override string ToString()
        {
            if (this.ScriptInfo != null)
            {
                return $"{this.ScriptInfo.Name}/{this.ScriptInfo.Version}";
            }
            return base.ToString();
        }
    }
}
