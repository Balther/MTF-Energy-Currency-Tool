codeunit 50104 GeneralMgt
{
    procedure CheckAdminUser()
    var
        ErrorMsg: Label 'This funtion is not valide for user %1.';
    begin
        //AdminUsers.Add('EXT_FWO');
        //if not AdminUsers.Contains(format(UserId)) then
        //    Error(ErrorMsg, UserId);
        MFTSetup.FindFirst();
        if (UserId <> MFTSetup.AdminUser1) and (UserId <> MFTSetup.AdminUser2) then
            ////if (UserId <> AdminUser1) and (UserId <> AdminUser2) then
            Error(ErrorMsg, UserId);
    end;

    procedure IsAdminUser(): Boolean
    var
    begin
        MFTSetup.FindFirst();
        exit((UserId = MFTSetup.AdminUser1) or (UserId = MFTSetup.AdminUser2));
        ////exit((UserId = AdminUser1) or (UserId = AdminUser2));
        //exit(AdminUsers.Contains(format(UserId)))
    end;

    var
        MFTSetup: Record "MFT - General Setup";
    ////AdminUser1: Label 'EXT_FWO';
    ////AdminUser2: Label 'RKS';
    //AdminUsers: List of [Text];

}
