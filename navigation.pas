unit Navigation;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, TANavigation;

type

  { TNavigationForm }

  TNavigationForm = class(TForm)
    ChartNavPanel1: TChartNavPanel;
  private

  public

  end;

var
  NavigationForm: TNavigationForm;

implementation

{$R *.lfm}

end.

