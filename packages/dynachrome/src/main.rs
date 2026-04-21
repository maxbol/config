use anyhow::{anyhow, Context};
use clap::Parser;
use gray_matter::{engine::YAML, Matter};
use regex::Regex;
use serde::de::{self, Deserializer, Unexpected, Visitor};
use serde::Deserialize;
use std::collections::HashMap;
use std::fmt;
use std::path::{Path, PathBuf};
use std::str::FromStr;

#[derive(Debug, Clone, Copy)]
struct RgbColor(u8, u8, u8);

#[derive(Debug, Clone, Copy)]
struct HsvColor(f64, f64, f64);

impl HsvColor {
    fn darken(&mut self, factor: f64) {
        self.2 = f64::min(self.2 - (self.2 * factor), 1.);
    }
    fn lighten(&mut self, factor: f64) {
        self.2 = f64::min(self.2 + (self.2 * factor), 1.);
    }
}

#[derive(Debug, Clone, thiserror::Error)]
enum ColorParseError {
    #[error("invalid length: expected 6, got {0}")]
    InvalidLength(usize),
    #[error("invalid hex value: {0}")]
    InvalidValue(String),
}
impl FromStr for RgbColor {
    type Err = ColorParseError;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        if s.len() != 6 {
            return Err(ColorParseError::InvalidLength(s.len()));
        }

        let r = u8::from_str_radix(&s[0..2], 16)
            .map_err(|_| ColorParseError::InvalidValue(s[0..2].to_string()))?;
        let g = u8::from_str_radix(&s[2..4], 16)
            .map_err(|_| ColorParseError::InvalidValue(s[2..4].to_string()))?;
        let b = u8::from_str_radix(&s[4..6], 16)
            .map_err(|_| ColorParseError::InvalidValue(s[4..6].to_string()))?;

        Ok(RgbColor(r, g, b))
    }
}

fn rgb_to_hsv(rgb: RgbColor) -> HsvColor {
    let rnorm: f64 = rgb.0 as f64 / 255.;
    let gnorm: f64 = rgb.1 as f64 / 255.;
    let bnorm: f64 = rgb.2 as f64 / 255.;

    let cmax = f64::max(rnorm, f64::max(gnorm, bnorm));
    let cmin = f64::min(rnorm, f64::min(gnorm, bnorm));

    let delta = cmax - cmin;

    let mut hue: f64 = if delta == 0. {
        0.
    } else if cmax == rnorm {
        60. * (((gnorm - bnorm) / delta) % 6.)
    } else if cmax == gnorm {
        60. * (((bnorm - rnorm) / delta) + 2.)
    } else {
        60. * (((rnorm - gnorm) / delta) + 4.)
    };

    if hue < 0. {
        hue += 360.;
    }

    let sat: f64 = match cmax {
        0. => 0.,
        _ => delta / cmax,
    };

    return HsvColor(hue, sat, cmax);
}

fn hsv_to_rgb(hsv: HsvColor) -> RgbColor {
    if hsv.1 == 0. {
        return RgbColor(
            (hsv.2 * 255.) as u8,
            (hsv.2 * 255.) as u8,
            (hsv.2 * 255.) as u8,
        );
    }

    let mut hue = hsv.0 as f64;

    if hue >= 360. {
        hue = 0.;
    }

    hue /= 60.;
    let hue_integer_part = hue as i64;
    let hue_ff = hue - (hue_integer_part as f64);

    let p = hsv.2 * (1. - hsv.1);
    let q = hsv.2 * (1. - (hsv.1 * hue_ff));
    let t = hsv.2 * (1. - (hsv.1 * (1. - hue_ff)));

    let (r, g, b) = match hue_integer_part {
        0 => (hsv.2, t, p),
        1 => (q, hsv.2, p),
        2 => (p, hsv.2, t),
        3 => (p, q, hsv.2),
        4 => (t, p, hsv.2),
        _ => (hsv.2, p, q),
    };

    return RgbColor((r * 255.) as u8, (g * 255.) as u8, (b * 255.) as u8);
}

impl<'de> Deserialize<'de> for RgbColor {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct ColorVisitor;

        impl<'de> Visitor<'de> for ColorVisitor {
            type Value = RgbColor;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("a string in the format rrggbb")
            }

            fn visit_str<E>(self, value: &str) -> Result<RgbColor, E>
            where
                E: de::Error,
            {
                if value.len() != 6 {
                    return Err(E::invalid_length(value.len(), &self));
                }

                RgbColor::from_str(value)
                    .map_err(|_| E::invalid_value(Unexpected::Str(value), &self))
            }
        }

        deserializer.deserialize_str(ColorVisitor)
    }
}

#[derive(Debug, Clone, Copy, Deserialize)]
enum Format {
    Hex,
    R,
    G,
    B,
}
impl FromStr for Format {
    type Err = anyhow::Error;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "hex" => Ok(Format::Hex),
            "r" => Ok(Format::R),
            "g" => Ok(Format::G),
            "b" => Ok(Format::B),
            _ => Err(anyhow!("Unknown format: {}", s)),
        }
    }
}

#[derive(Debug, Clone, Deserialize)]
struct Frontmatter {
    defines: HashMap<String, String>,
}

#[derive(Debug, Parser)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Name of the template file
    pub template: PathBuf,

    /// Name of the palette file
    pub palette: PathBuf,

    /// Assign the given color values for the specified names.
    /// The format is `NAME=COLOR`, where `COLOR` is a hex value in the format `rrggbb`.
    /// Note that there is no leading `#`.
    ///
    /// These overrides are applied both to the palette and after the frontmatter defines.
    #[arg(short, long="override", num_args = 1, value_parser = parse_key_val::<String, RgbColor>)]
    pub overrides: Vec<(String, RgbColor)>,
}

fn parse_key_val<T, U>(s: &str) -> Result<(T, U), Box<dyn std::error::Error + Send + Sync>>
where
    T: std::str::FromStr,
    T::Err: std::error::Error + Send + Sync + 'static,
    U: std::str::FromStr,
    U::Err: std::error::Error + Send + Sync + 'static,
{
    let pos = s
        .find('=')
        .ok_or_else(|| format!("invalid KEY=value: no `=` found in `{}`", s))?;
    Ok((s[..pos].parse()?, s[pos + 1..].parse()?))
}

type Palette = HashMap<String, RgbColor>;

#[derive(Debug, Clone, Deserialize)]
struct PaletteFile {
    pub semantic: Palette,
    pub colors: Palette,
    pub accents: Palette,
}

fn load_palette(path: &Path) -> anyhow::Result<Palette> {
    let content = std::fs::read_to_string(path).context("Failed to read palette file")?;
    let palette_file: PaletteFile =
        serde_json::from_str(&content).context("Failed to parse palette file")?;
    let mut palette = palette_file.semantic;
    palette.extend(palette_file.colors);
    palette.extend(palette_file.accents);

    Ok(palette)
}

fn apply_overrides(palette: &mut Palette, overrides: &[(String, RgbColor)]) -> anyhow::Result<()> {
    for (name, color) in overrides {
        palette.insert(name.clone(), *color);
    }
    Ok(())
}

fn replace_colors(template: &str, palette: &Palette) -> anyhow::Result<String> {
    let re = Regex::new(r"⟨([^:⟩]+):([^⟩]+)⟩")?;
    let mut result = String::with_capacity(template.len());
    let mut last_end = 0;
    for caps in re.captures_iter(template) {
        let m = caps.get(0).unwrap();
        result.push_str(&template[last_end..m.start()]);
        let name = caps.get(1).unwrap().as_str();
        let format = caps.get(2).unwrap().as_str();
        let color = palette
            .get(name)
            .ok_or_else(|| anyhow!("Unknown color: {}", name))?;
        result.push_str(&format_color(*color, Format::from_str(format)?));
        last_end = m.end();
    }
    result.push_str(&template[last_end..]);
    Ok(result)
}

fn format_color(color: RgbColor, fmt: Format) -> String {
    match fmt {
        Format::Hex => format!("{:02x}{:02x}{:02x}", color.0, color.1, color.2),
        Format::R => format!("{}", color.0),
        Format::G => format!("{}", color.1),
        Format::B => format!("{}", color.2),
    }
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();

    let template = std::fs::read_to_string(&args.template).context(format!(
        "Failed to read template file: {}",
        args.template.to_string_lossy()
    ))?;
    let mut palette = load_palette(&args.palette)?;
    apply_overrides(&mut palette, &args.overrides)?;

    let matter = Matter::<YAML>::new();
    let entity = matter.parse(&template);

    let frontmatter = entity
        .data
        .map(|data| data.deserialize::<Frontmatter>())
        .transpose()
        .context("Failed to parse frontmatter")?;
    if let Some(frontmatter) = frontmatter {
        for (name, value) in frontmatter.defines {
            let parts: Vec<&str> = value.split(":").collect();
            let mut color = palette
                .get(parts[0])
                .ok_or_else(|| anyhow!("Unknown color: {}", value))?
                .clone();

            if parts.len() > 1 {
                let mut hsv_color = rgb_to_hsv(color);
                let op_re = Regex::new(r"^([^\(]+)(?:\(([0-9.]+)\))?$")?;
                for op in &parts[1..] {
                    if let Some(caps) = op_re.captures(op) {
                        let op_name = &caps[1];
                        // Unwrap for now in lieu of real error management
                        let arg = caps.get(2).map(|arg| arg.as_str().parse::<f64>().unwrap());

                        match op_name {
                            "darken" => {
                                hsv_color.darken(arg.unwrap_or(0.));
                            }
                            "lighten" => {
                                hsv_color.lighten(arg.unwrap_or(0.));
                            }
                            _ => {}
                        }
                    }
                }
                color = hsv_to_rgb(hsv_color);
            }

            palette.insert(name, color);
        }
    }
    apply_overrides(&mut palette, &args.overrides)?;

    let result = replace_colors(&entity.content, &palette)?;
    println!("{}", result);

    Ok(())
}
