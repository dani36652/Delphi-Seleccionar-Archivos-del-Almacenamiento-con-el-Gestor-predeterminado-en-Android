unit UPrincipal;

interface

uses
  //================================================================================================
  System.Permissions,fmx.Platform,fmx.Platform.Android,
  Androidapi.jni,fmx.helpers.android, Androidapi.Jni.app,
  Androidapi.Jni.GraphicsContentViewText, Androidapi.JniBridge,
  FMX.ScrollBox, FMX.Memo,Androidapi.JNI.Os, Androidapi.Jni.Telephony,
  Androidapi.JNI.JavaTypes,idUri,Androidapi.JNI.NET, Androidapi.Helpers,
  Androidapi.JNI.Widget, system.UITypes, system.Threading, system.Classes,
  system.SysUtils, system.Types, FMX.Forms,FMX.Types, fmx.Dialogs, Androidapi.jni.Provider,
  fmx.DialogService, FMX.Objects, FMX.StdCtrls, FMX.Controls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Edit, System.Messaging, FMX.Media;
//===================================================================================;


type
  TFrmPrincipal = class(TForm)
    BtnSeleccionar: TButton;
    EdtRuta: TEdit;
    player: TMediaPlayer;
    StyleBook1: TStyleBook;
    Imagen: TImage;
    Layout1: TLayout;
    Switch1: TSwitch;
    lblSeleccion: TLabel;
    procedure BtnSeleccionarClick(Sender: TObject);
    procedure Switch1Switch(Sender: TObject);
  private
    { Private declarations }
    procedure HandleActivityMessage(const Sender:TObject; const M:TMessage);
    procedure OnActivityResult(RequestCode,ResultCode:Integer; Intent:JIntent);
    var FMessageSuscriptionID:integer;
  public
    { Public declarations }
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation
uses
System.IOUtils;

{$R *.fmx}

{ TFrmPrincipal }

procedure TFrmPrincipal.BtnSeleccionarClick(Sender: TObject);
var intent:JIntent;
begin
FMessageSuscriptionID:= TMessageManager.DefaultManager.SubscribeToMessage
(TMessageResultNotification, HandleActivityMessage);
intent:=TJIntent.JavaClass.init;
intent.setAction(TJIntent.JavaClass.ACTION_GET_CONTENT);
 if Switch1.IsChecked then
 intent.setType(StringToJString('image/*')) else
 intent.setType(StringToJString('audio/*'));
 TAndroidHelper.Activity.startActivityForResult(intent,0);
end;

procedure TFrmPrincipal.HandleActivityMessage(const Sender: TObject; const M: TMessage);
begin
if M is TMessageResultNotification then
OnActivityResult(TMessageResultNotification(M).RequestCode, TMessageResultNotification(M).ResultCode,
TMessageResultNotification(M).Value);
end;

procedure  TFrmPrincipal.OnActivityResult(RequestCode, ResultCode: Integer;
  Intent: JIntent);
 var filename:string;
 uri:JNet_Uri;
 ms:TMemoryStream;
 jis:JinputStream;
 b:TJavaArray<Byte>;
 Toast:JToast;
begin
TMessageManager.DefaultManager.Unsubscribe(TMessageResultNotification, FMessageSuscriptionID);
FMessageSuscriptionID:=0;
if RequestCode =0 then {lo que se pone en el intent como request code}
 begin
  if ResultCode = TJActivity.JavaClass.RESULT_OK then
   begin
   if Assigned(Intent) then
    begin
    filename := JStringToString(Intent.getDataString);
    EdtRuta.Text:= filename;
     try
     uri:=StrToJURI(filename);
     ms:=TMemoryStream.Create;
     ms.Seek(0,0);
     jis:=TAndroidHelper.Context.getContentResolver.openInputStream(uri);
     b:=TJavaArray<Byte>.Create(jis.available);
     jis.read(b);
     ms.Write(b.Data^,b.Length);
      try
       if player.State=TMediaState.Playing then
       player.Stop;

       if Switch1.IsChecked then Imagen.Bitmap.LoadFromStream(ms)
       else
       begin
        Toast:=TJToast.JavaClass.makeText(TAndroidHelper.Context,
        StrToJCharSequence('Reproduciendo...'),TJToast.JavaClass.LENGTH_SHORT);
        Toast.setGravity(TJGravity.JavaClass.CENTER,0,0);
        Toast.show;
        if tfile.Exists(TPath.GetDocumentsPath+PathDelim+'Audio.mp3') then
        begin
        tfile.Delete(TPath.GetDocumentsPath+PathDelim+'Audio.mp3');
        end;
        ms.SaveToFile(TPath.GetDocumentsPath+PathDelim+'Audio.mp3');
        player.FileName:=TPath.GetDocumentsPath+PathDelim+'Audio.mp3';
        player.Play;
       end;
      except on E:exception do
      ShowMessage(E.ClassName+' Error Motivo: '+E.Message);
      end;
     finally
     FreeAndNil(ms);
     jis.close;
     end;
    end;
   end
  else if ResultCode = TJActivity.JavaClass.RESULT_CANCELED then
  begin
  EdtRuta.Text:='';
  ShowMessage('Selecci?n cancelada');
  end;
 end;
end;
procedure TFrmPrincipal.Switch1Switch(Sender: TObject);
begin
 if Switch1.IsChecked then
  begin
  lblSeleccion.Text:= 'Selecci?n de Imagen';
  end else
  begin
  lblSeleccion.Text:= 'Selecci?n de Audio';
  end;
end;

end.
