import unittest
from unittest.mock import patch, MagicMock
import sys
import subprocess
import os

sys.path.append(os.getcwd())

import scripts.setup_secrets as script

class TestSetupSecrets(unittest.TestCase):

    @patch('scripts.setup_secrets.subprocess.run')
    @patch('scripts.setup_secrets.generate_password')
    def test_alphanumeric(self, mock_gen, mock_run):
        mock_gen.return_value = "test_pass_123"
        
        with patch('sys.argv', ['scripts.setup_secrets.py', '--name', 'key1', '--length', '10', '--type', 'alphanumeric']):
            script.main()
            
            mock_gen.assert_called_with(10, "alphanumeric")
            mock_run.assert_called_once()
            args = mock_run.call_args[0][0]
            self.assertEqual(args[0], "bw")
            # Check that the key name and the password appear as substrings in the command arguments
            self.assertTrue(any("key1" in arg for arg in args))
            self.assertTrue(any("test_pass_123" in arg for arg in args))

    @patch('scripts.setup_secrets.subprocess.run')
    @patch('scripts.setup_secrets.generate_password')
    def test_complex(self, mock_gen, mock_run):
        mock_gen.return_value = "complex!@#123"
        
        with patch('sys.argv', ['scripts.setup_secrets.py', '--name', 'key2', '--length', '20', '--type', 'complex']):
            script.main()
            
            mock_gen.assert_called_with(20, "complex")
            mock_run.assert_called_once()
            args = mock_run.call_args[0][0]
            self.assertEqual(args[0], "bw")
            self.assertTrue(any("key2" in arg for arg in args))
            self.assertTrue(any("complex!@#123" in arg for arg in args))

    def test_invalid_type(self):
        with patch('sys.argv', ['scripts/setup_secrets.py', '--name', 'key', '--length', '10', '--type', 'wrong']):
            with self.assertRaises(SystemExit):
                script.main()

    @patch('scripts.setup_secrets.subprocess.run')
    def test_cli_missing(self, mock_run):
        mock_run.side_effect = FileNotFoundError
        
        with patch('sys.argv', ['scripts/setup_secrets.py', '--name', 'key', '--length', '10', '--type', 'alphanumeric']):
            with self.assertRaises(SystemExit):
                script.main()

if __name__ == "__main__":
    unittest.main()
