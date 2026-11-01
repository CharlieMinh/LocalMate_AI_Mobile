[CmdletBinding()]
param(
    [string]$EvidenceDirectory = 'build/icon-review'
)

# Technical exports from the imagegen-created transparent artwork; no brand redraw.
$ErrorActionPreference = 'Stop'
$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not [IO.Path]::IsPathRooted($EvidenceDirectory)) {
    $EvidenceDirectory = Join-Path $repositoryRoot $EvidenceDirectory
}
Add-Type -AssemblyName System.Drawing
$optionalDrawingReferences = foreach ($assemblyName in @('System.Private.Windows.GdiPlus', 'System.Private.Windows.Core')) {
    try { [Reflection.Assembly]::Load($assemblyName).Location }
    catch [IO.FileNotFoundException] { }
}
$drawingReferences = (@(
    [Drawing.Bitmap].Assembly.Location,
    [Drawing.Color].Assembly.Location,
    [System.ComponentModel.Component].Assembly.Location,
    'System.Runtime'
) + @($optionalDrawingReferences)) | Select-Object -Unique
Add-Type -ReferencedAssemblies $drawingReferences -TypeDefinition @'
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class LocalMateIconExport {
    private static Rectangle bounds;
    private static double radius;

    private static Bitmap Render(Bitmap artwork, int size, double radiusRatio, bool white, bool round) {
        Bitmap result = new Bitmap(size, size, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(result)) {
            g.Clear(Color.Transparent);
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            if (white) {
                if (round) g.FillEllipse(Brushes.White, 0, 0, size, size);
                else g.Clear(Color.White);
            }
            float scale = (float)(size * radiusRatio / radius);
            float width = bounds.Width * scale;
            float height = bounds.Height * scale;
            g.DrawImage(artwork, new RectangleF((size-width)/2, (size-height)/2, width, height), bounds, GraphicsUnit.Pixel);
        }
        return result;
    }

    private static GraphicsPath Rounded(float x, float y, float size, float r) {
        GraphicsPath p = new GraphicsPath();
        p.AddArc(x, y, r*2, r*2, 180, 90);
        p.AddArc(x+size-r*2, y, r*2, r*2, 270, 90);
        p.AddArc(x+size-r*2, y+size-r*2, r*2, r*2, 0, 90);
        p.AddArc(x, y+size-r*2, r*2, r*2, 90, 90);
        p.CloseFigure();
        return p;
    }

    public static string Export(string root, string evidence) {
        Directory.CreateDirectory(evidence);
        string res = Path.Combine(root, "android/app/src/main/res");
        using (Bitmap source = new Bitmap(Path.Combine(root, "assets/brand/app-icon-mark.png"))) {
            int minX=source.Width, minY=source.Height, maxX=-1, maxY=-1;
            for (int y=0; y<source.Height; y++) for (int x=0; x<source.Width; x++) {
                if (source.GetPixel(x,y).A >= 16) {
                    minX=Math.Min(minX,x); minY=Math.Min(minY,y);
                    maxX=Math.Max(maxX,x); maxY=Math.Max(maxY,y);
                }
            }
            if (maxX < 0) throw new InvalidOperationException("Artwork has no visible pixels.");
            bounds = Rectangle.FromLTRB(minX,minY,maxX+1,maxY+1);
            double cx=(minX+maxX)/2.0, cy=(minY+maxY)/2.0;
            radius=0;
            for (int y=minY; y<=maxY; y++) for (int x=minX; x<=maxX; x++) {
                if (source.GetPixel(x,y).A >= 16) {
                    radius=Math.Max(radius,Math.Sqrt((x-cx)*(x-cx)+(y-cy)*(y-cy)));
                }
            }
            string[] dpi={"mdpi","hdpi","xhdpi","xxhdpi","xxxhdpi"};
            int[] sizes={48,72,96,144,192};
            for (int i=0; i<dpi.Length; i++) {
                string folder=Path.Combine(res,"mipmap-"+dpi[i]);
                Directory.CreateDirectory(folder);
                using (Bitmap icon=Render(source,sizes[i],0.43,true,false)) icon.Save(Path.Combine(folder,"ic_launcher.png"),ImageFormat.Png);
                using (Bitmap icon=Render(source,sizes[i],0.43,true,true)) icon.Save(Path.Combine(folder,"ic_launcher_round.png"),ImageFormat.Png);
            }
            string drawable=Path.Combine(res,"drawable-nodpi");
            Directory.CreateDirectory(drawable);
            // Entire visible artwork fits a radius of 31dp within the central 66dp safe zone.
            using (Bitmap foreground=Render(source,432,31.0/108.0,false,false)) {
                double exportedRadius=0;
                for (int y=0;y<432;y++) for (int x=0;x<432;x++) {
                    if (foreground.GetPixel(x,y).A >= 16)
                        exportedRadius=Math.Max(exportedRadius,Math.Sqrt((x-215.5)*(x-215.5)+(y-215.5)*(y-215.5)));
                }
                if (exportedRadius > 132) throw new InvalidOperationException("Foreground exceeds adaptive-icon safe circle.");
                foreground.Save(Path.Combine(drawable,"ic_launcher_foreground.png"),ImageFormat.Png);
            }
            using (Bitmap monochrome=new Bitmap(source.Width,source.Height,PixelFormat.Format32bppArgb)) {
                for (int y=minY;y<=maxY;y++) for (int x=minX;x<=maxX;x++) {
                    Color c=source.GetPixel(x,y);
                    double coverage=Math.Min(1.0,(255-Math.Min(c.R,Math.Min(c.G,c.B)))/32.0);
                    monochrome.SetPixel(x,y,Color.FromArgb((int)Math.Round(c.A*coverage),255,255,255));
                }
                using (Bitmap mono=Render(monochrome,432,31.0/108.0,false,false))
                    mono.Save(Path.Combine(drawable,"ic_launcher_monochrome.png"),ImageFormat.Png);
                using (Bitmap preview=new Bitmap(1200,360,PixelFormat.Format32bppArgb))
                using (Graphics g=Graphics.FromImage(preview))
                using (Font font=new Font("Segoe UI",16,FontStyle.Regular))
                using (Brush ink=new SolidBrush(Color.FromArgb(15,33,72))) {
                    g.Clear(Color.FromArgb(244,246,250));
                    g.SmoothingMode=SmoothingMode.AntiAlias;
                    string[] labels={"Play Store 512", "Round launcher", "Rounded launcher", "Themed icon"};
                    for (int i=0;i<4;i++) {
                        int x=i*300+30;
                        using (Bitmap tile=Render(i==3?monochrome:source,240,0.43,i!=3,false)) {
                            GraphicsState state=g.Save();
                            if (i==1) {
                                using(GraphicsPath circle=new GraphicsPath()) {
                                    circle.AddEllipse(x,30,240,240); g.SetClip(circle);
                                }
                            } else if (i>=2) {
                                using(GraphicsPath rounded=Rounded(x,30,240,52)) g.SetClip(rounded);
                            }
                            if (i==3) using(Brush navy=new SolidBrush(Color.FromArgb(29,62,130))) g.FillRectangle(navy,x,30,240,240);
                            g.DrawImage(tile,x,30);
                            g.Restore(state);
                        }
                        g.DrawString(labels[i],font,ink,x,296);
                    }
                    preview.Save(Path.Combine(evidence,"icon-preview.png"),ImageFormat.Png);
                }
            }
            using (Bitmap play=Render(source,512,0.43,true,false))
                play.Save(Path.Combine(root,"assets/brand/app-icon-play-512.png"),ImageFormat.Png);
            return "Legacy icons: 48/72/96/144/192 px; adaptive foreground: 432px, within 66dp safe circle; Play icon: opaque 512px; original artwork preserved.";
        }
    }
}
'@
[LocalMateIconExport]::Export($repositoryRoot, $EvidenceDirectory)
