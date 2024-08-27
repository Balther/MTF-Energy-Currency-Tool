// Welcome to your new AL extension.
// Remember that object names and IDs should be unique across all extensions.
// AL snippets start with t*, like tpageext - give them a try and happy coding!

pageextension 50110 MFTSetup extends "MFT General Setup"
{
    layout
    {
        addafter("Job Queue Handling")
        {
            group(CurrencyConversion) //Group is not mandatory
            {
                Caption = 'Currency Conversion';
                Visible = ShowAdmin;
                //Visible = true;

                field(SourceCompany; Rec.SourceCompany)
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the source company for currency conversion.';
                    Visible = ShowAdmin;
                    //Visible = true;
                    //ShowMandatory = VariantCodeMandatory;

                    trigger OnValidate()
                    var

                    begin

                    end;
                }
                field(DocumentNo; Rec.DocumentNo)
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the document no. for opening entries in currency conversion.';
                    Visible = ShowAdmin;
                    //Visible = true;
                    //ShowMandatory = VariantCodeMandatory;
                }
                field(CutOffDate; Rec.CutOffDate)
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the cut-off date for opening entries in currency conversion.';
                    Visible = ShowAdmin;
                }
                field(BankEntryLevel; rec.BankEntryLevel)
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the posting detail level at bank account ledger entry level instead of bank account balance level.';
                    Visible = ShowAdmin;
                }
                field(SplitBalAccToSeparateLine; Rec.SplitBalAccToSeparateLine)
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the balancing posting enabled as separate journal line.';
                    Visible = ShowAdmin;
                }
                field(AdminUser1; Rec.AdminUser1)
                {
                    ApplicationArea = all;
                    ToolTip = 'Administration users are the only users to whom currency conversion tool elements are shown, and the only users, who can use the tool - An administration user can only be set by another administration user.';
                    Visible = ShowAdmin;
                }
                field(AdminUser2; Rec.AdminUser2)
                {
                    ApplicationArea = all;
                    ToolTip = 'Administration users are the only users to whom currency conversion tool elements are shown, and the only users, who can use the tool - An administration user can only be set by another administration user.';
                    Visible = ShowAdmin;
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        rec.FindFirst();
        if rec.AdminUser1 = '' then begin
            Rec.AdminUser1 := 'RKS';
            rec.Modify();
        end;
        if rec.AdminUser2 = '' then begin
            Rec.AdminUser2 := 'EXT_FWO';
            rec.Modify();
        end;

        ShowAdmin := GenMgt.IsAdminUser;
        ////ShowAdmin := true;
        //Message(UserId); ////
    end;

    var
        GenMgt: Codeunit GeneralMgt;
        ShowAdmin: Boolean;
}