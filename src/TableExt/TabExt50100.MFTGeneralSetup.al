tableextension 50100 "MFT GeneralLedgerSetup" extends "MFT - General Setup"
{
    fields
    {
        field(50100; "SourceCompany"; Text[30])
        {
            Caption = 'Source Company';
            //DataClassification = 
            TableRelation = Company;
        }
        field(50101; "DocumentNo"; Code[20])
        {
            Caption = 'Document No.';
            //DataClassification = 
            InitValue = 'OPENING2024'; //+ format(Date2DMY(TODAY,3));
        }
        field(50102; "CutOffDate"; Date)
        {
            Caption = 'Cut-Off Date';
            //DataClassification = 
            InitValue = 20240331D; ////
        }
        field(50103; "BankEntryLevel"; Boolean)
        {
            Caption = 'Bank Ledger Entry Level Posting';
        }
        field(50104; SplitBalAccToSeparateLine; Boolean)
        {
            Caption = 'Split Balancing Account Posting into Separate Journal Line';
        }
        field(50105; AdminUser1; Code[50])
        {
            Caption = 'Administrator User 1';
            //ToolTip = 'Administration users are the only users to whom currency conversion tool elements are shown, and the only users, who can use the tool - An administration user can only be set by another administration user.';
            //DataClassification = ToBeClassified;
            TableRelation = User."User Name";
            //InitValue = 'RKS';
        }
        field(50106; AdminUser2; Code[50])
        {
            Caption = 'Administrator User 2';
            //ToolTip = 'Administration users are the only users to whom currency conversion tool elements are shown, and the only users, who can use the tool - An administration user can only be set by another administration user.';
            //DataClassification = ToBeClassified;
            TableRelation = User."User Name";
            //InitValue = 'EXT_FWO';
        }
    }
}
