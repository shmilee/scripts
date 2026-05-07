use std::fs::File;
use std::io::Write;
use std::ops::{Add, AddAssign, Mul, Sub};

/// 简单的二维向量结构体，用于处理位置、速度和力
#[derive(Debug, Clone, Copy)]
struct Vec2 {
    x: f64,
    y: f64,
}

// 为 Vec2 实现基础的数学运算，方便写物理公式
impl Vec2 {
    fn new(x: f64, y: f64) -> Self {
        Vec2 { x, y }
    }

    fn magnitude_squared(&self) -> f64 {
        self.x * self.x + self.y * self.y
    }

    fn magnitude(&self) -> f64 {
        self.magnitude_squared().sqrt()
    }
}

// 重新实现更简洁的运算符重载
impl AddAssign for Vec2 {
    fn add_assign(&mut self, other: Self) {
        self.x += other.x;
        self.y += other.y;
    }
}

// 为了演示方便，我们手动实现简单的运算符逻辑
impl Add for Vec2 {
    type Output = Self;
    fn add(self, rhs: Self) -> Self {
        Vec2::new(self.x + rhs.x, self.y + rhs.y)
    }
}

impl Sub for Vec2 {
    type Output = Self;
    fn sub(self, rhs: Self) -> Self {
        Vec2::new(self.x - rhs.x, self.y - rhs.y)
    }
}

impl Mul<f64> for Vec2 {
    type Output = Self;
    fn mul(self, rhs: f64) -> Self {
        Vec2::new(self.x * rhs, self.y * rhs)
    }
}

// 借用这个简单的结构体表示天体
struct Body {
    mass: f64,
    pos: Vec2,
    vel: Vec2,
}

impl Body {
    fn new(mass: f64, pos: Vec2, vel: Vec2) -> Self {
        Body {
            mass,
            pos,
            vel,
        }
    }
}

/// 计算两个天体在当前位置下的加速度
fn compute_acceleration(g: f64, pos_a: Vec2, pos_b: Vec2, mass_a: f64, mass_b: f64) -> (Vec2, Vec2) {
    let r_vec = pos_a - pos_b;
    let dist_sq = r_vec.magnitude_squared();
    let dist = dist_sq.sqrt();
    let force_mag = (g * mass_a * mass_b) / dist_sq;
    let force_vec = r_vec * (force_mag / dist);
    let acc_a = force_vec * (-1.0 / mass_a);
    let acc_b = force_vec * (1.0 / mass_b);
    (acc_a, acc_b)
}

fn main() {
    // 万有引力常数 G (为了演示方便，我们取一个较大的值，让运动明显)
    let g: f64 = 1.0;
    // 时间步长 (dt)
    let dt: f64 = 0.0005;
    // 总模拟步数
    let steps = 10000;

    // 初始化两个天体
    // 天体 A：静止在原点
    let mut body_a = Body::new(100.0, Vec2::new(0.0, 0.0), Vec2::new(0.0, 0.0));
    // 天体 B：有初始速度，绕着 A 运行
    let mut body_b = Body::new(0.01, Vec2::new(1.0, 0.0), Vec2::new(0.0, 10.0));

    let mut out = File::create("2body.txt").expect("Failed to create output file");
    writeln!(out, "Step     Ax        Ay        Bx        By        KE_B      PE_B").unwrap();

    for step in 0..steps+1 {
        // 1. 计算当前加速度
        let (acc_a, acc_b) = compute_acceleration(g, body_a.pos, body_b.pos, body_a.mass, body_b.mass);

        // 2. Velocity Verlet 更新位置: p(t+dt) = p(t) + v(t)*dt + 0.5*a(t)*dt²
        body_a.pos += body_a.vel * dt + acc_a * (0.5 * dt * dt);
        body_b.pos += body_b.vel * dt + acc_b * (0.5 * dt * dt);

        // 3. 计算新位置处的加速度
        let (acc_a_new, acc_b_new) = compute_acceleration(g, body_a.pos, body_b.pos, body_a.mass, body_b.mass);

        // 4. Velocity Verlet 更新速度: v(t+dt) = v(t) + 0.5*(a(t) + a(t+dt))*dt
        body_a.vel += (acc_a + acc_a_new) * (0.5 * dt);
        body_b.vel += (acc_b + acc_b_new) * (0.5 * dt);

        // 每 100 步写入一次结果
        if step % 100 == 0 {
            let dist = (body_a.pos - body_b.pos).magnitude();
            let ke = 0.5 * body_b.mass * body_b.vel.magnitude_squared();
            let pe = -(g * body_a.mass * body_b.mass) / dist;
            writeln!(out, "{:4} {:6.2} {:6.2} {:6.2} {:6.2} {:9.4} {:9.4}",
                step, body_a.pos.x, body_a.pos.y, body_b.pos.x, body_b.pos.y, ke, pe
            ).unwrap();
        }
    }
}
