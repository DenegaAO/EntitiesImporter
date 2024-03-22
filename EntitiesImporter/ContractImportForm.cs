using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.OleDb;
using System.Data.SqlClient;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.IO;

namespace EntitiesImporter
{
    public partial class ContractImportForm : System.Windows.Forms.Form
    {
        public ContractImportForm(string connectionString)
        {
            InitializeComponent();
            SqlConnection connection = new SqlConnection(connectionString);
        }

        private void buttonSelectRegister_Click(object sender, EventArgs e)
        {
            openFileDialog.InitialDirectory = "c:\\Реестры для загрузки";
            openFileDialog.Filter = "txt files (*.txt)|*.txt|All files (*.*)|*.*";
            openFileDialog.FilterIndex = 1;
            openFileDialog.RestoreDirectory = true;
            if (openFileDialog.ShowDialog() == DialogResult.OK)
            {
                textBoxFileName.Text = openFileDialog.FileName;
                buttonOk.Enabled = true;
            }
            else
            {
                textBoxFileName.Text = string.Empty;
                buttonOk.Enabled = false;
            }
        }

        private void buttonOk_Click(object sender, EventArgs e)
        {
            StreamReader f = new StreamReader(textBoxFileName.Text, Encoding.GetEncoding(1251));
            while (!f.EndOfStream)
            {
                string DocString = f.ReadLine();
                textBoxInfo.Text = DocString;
            }
            f.Close();
        }
    }
}
