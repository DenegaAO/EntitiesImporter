using System.Data;
using System.Data.OleDb;
using System.Data.SqlClient;

using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace EntitiesImporter
{
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        private static void Main()
        {
            string[] args = Environment.GetCommandLineArgs();
            string ServerName = args[1];
            string DataBaseName = args[2];
            string PodCast = args[3];
            string connectionString = "Server=(" + ServerName + ")\\mssqllocaldb;Database=" + DataBaseName + "; Trusted_Connection=True;";

            Application.EnableVisualStyles();
			Application.SetCompatibleTextRenderingDefault(false);
            if (PodCast == "Contract")
            {
                var ContractImportForm = new ContractImportForm(connectionString);
                Application.Run(ContractImportForm);
            }
            else MessageBox.Show("Функция " + PodCast + " не реализована", "Импорт сущностей в ПК OmniUS");
		}
	}
}
